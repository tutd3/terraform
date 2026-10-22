# --- Karpenter: IAM (node role + controller policy), SQS interruption
#     queue, EventBridge rule, dan tag discovery subnet/security group.
#
# Karpenter sendiri (controller pod + manifest NodePool/EC2NodeClass di
# Kubernetes) TIDAK ter-install di sini - itu langkah terpisah (Helm). Semua
# resource di file ini cuma menyiapkan sisi AWS-nya.
#
# Semua IAM policy di sini diambil PERSIS dari CloudFormation resmi AWS
# (bukan ditulis manual) - supaya tidak ada permission yang kurang/salah:
# https://raw.githubusercontent.com/aws/karpenter-provider-aws/main/website/content/en/preview/getting-started/getting-started-with-karpenter/cloudformation.yaml

data "aws_region" "current" {
  count = var.enable_karpenter ? 1 : 0
}

data "aws_caller_identity" "current" {
  count = var.enable_karpenter ? 1 : 0
}

data "aws_partition" "current" {
  count = var.enable_karpenter ? 1 : 0
}

locals {
  karpenter_region     = var.enable_karpenter ? data.aws_region.current[0].name : null
  karpenter_account_id = var.enable_karpenter ? data.aws_caller_identity.current[0].account_id : null
  karpenter_partition  = var.enable_karpenter ? data.aws_partition.current[0].partition : null
}

# --- Role untuk NODE yang nanti dibuat Karpenter (EC2 instance baru) - beda
#     dari aws_iam_role.node yang dipakai node group static di atas.
#     Karpenter sendiri yang bikin instance profile-nya secara dinamis (lewat
#     izin di IAMIntegrationPolicy di bawah) - kita tidak perlu bikin
#     instance profile manual di sini.
data "aws_iam_policy_document" "karpenter_node_assume" {
  count = var.enable_karpenter ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "karpenter_node" {
  count              = var.enable_karpenter ? 1 : 0
  name               = "KarpenterNodeRole-${var.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.karpenter_node_assume[0].json
}

resource "aws_iam_role_policy_attachment" "karpenter_node" {
  for_each = var.enable_karpenter ? toset([
    "arn:${local.karpenter_partition}:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:${local.karpenter_partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:${local.karpenter_partition}:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
    "arn:${local.karpenter_partition}:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]) : toset([])

  role       = aws_iam_role.karpenter_node[0].name
  policy_arn = each.value
}

# --- SQS queue untuk interruption notification (spot interruption, instance
#     state-change, rebalance recommendation, AWS Health event, dll) ---
resource "aws_sqs_queue" "karpenter_interruption" {
  count                     = var.enable_karpenter ? 1 : 0
  name                      = var.cluster_name
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true
}

data "aws_iam_policy_document" "karpenter_interruption_queue" {
  count = var.enable_karpenter ? 1 : 0

  statement {
    sid    = "EC2InterruptionPolicy"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "sqs.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.karpenter_interruption[0].arn]
  }

  statement {
    sid    = "DenyHTTP"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.karpenter_interruption[0].arn]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_sqs_queue_policy" "karpenter_interruption" {
  count     = var.enable_karpenter ? 1 : 0
  queue_url = aws_sqs_queue.karpenter_interruption[0].id
  policy    = data.aws_iam_policy_document.karpenter_interruption_queue[0].json
}

locals {
  # Event rule yang dikirim ke interruption queue - persis 5 rule dari
  # CloudFormation resmi.
  karpenter_event_rules = var.enable_karpenter ? {
    scheduled_change = {
      source      = ["aws.health"]
      detail_type = ["AWS Health Event"]
    }
    spot_interruption = {
      source      = ["aws.ec2"]
      detail_type = ["EC2 Spot Instance Interruption Warning"]
    }
    rebalance = {
      source      = ["aws.ec2"]
      detail_type = ["EC2 Instance Rebalance Recommendation"]
    }
    instance_state_change = {
      source      = ["aws.ec2"]
      detail_type = ["EC2 Instance State-change Notification"]
    }
    capacity_reservation = {
      source      = ["aws.ec2"]
      detail_type = ["EC2 Capacity Reservation Instance Interruption Warning"]
    }
  } : {}
}

resource "aws_cloudwatch_event_rule" "karpenter_interruption" {
  for_each = local.karpenter_event_rules

  # Prefix "karp" (bukan "karpenter") supaya tetap di bawah limit AWS 64
  # karakter untuk nama rule - "wetech-production-eks-karpenter-capacity_..."
  # kepanjangan.
  name = substr("${var.cluster_name}-karp-${each.key}", 0, 64)
  event_pattern = jsonencode({
    source      = each.value.source
    detail-type = each.value.detail_type
  })
}

resource "aws_cloudwatch_event_target" "karpenter_interruption" {
  for_each = local.karpenter_event_rules

  rule = aws_cloudwatch_event_rule.karpenter_interruption[each.key].name
  arn  = aws_sqs_queue.karpenter_interruption[0].arn
}

# --- Tag discovery - Karpenter pakai tag ini untuk tahu subnet & security
#     group mana yang boleh dipakai bikin node baru (diatur lewat
#     EC2NodeClass nanti, subnetSelectorTerms/securityGroupSelectorTerms).
resource "aws_ec2_tag" "karpenter_subnet_discovery" {
  for_each = var.enable_karpenter ? toset(local.node_subnet_ids) : toset([])

  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

resource "aws_ec2_tag" "karpenter_sg_discovery" {
  count = var.enable_karpenter ? 1 : 0

  resource_id = local.cluster_sg_id
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

# --- IAM policy controller Karpenter (gabungan 6 policy resmi dari
#     CloudFormation AWS - lihat file JSON masing-masing di ./files/) ---
resource "aws_iam_policy" "karpenter_node_lifecycle" {
  count = var.enable_karpenter ? 1 : 0
  name  = "KarpenterControllerNodeLifecyclePolicy-${var.cluster_name}"
  policy = templatefile("${path.module}/files/karpenter-node-lifecycle-policy.json.tftpl", {
    partition    = local.karpenter_partition
    region       = local.karpenter_region
    cluster_name = var.cluster_name
  })
}

resource "aws_iam_policy" "karpenter_iam_integration" {
  count = var.enable_karpenter ? 1 : 0
  name  = "KarpenterControllerIAMIntegrationPolicy-${var.cluster_name}"
  policy = templatefile("${path.module}/files/karpenter-iam-integration-policy.json.tftpl", {
    partition               = local.karpenter_partition
    region                  = local.karpenter_region
    account_id              = local.karpenter_account_id
    cluster_name            = var.cluster_name
    karpenter_node_role_arn = aws_iam_role.karpenter_node[0].arn
  })
}

resource "aws_iam_policy" "karpenter_eks_integration" {
  count = var.enable_karpenter ? 1 : 0
  name  = "KarpenterControllerEKSIntegrationPolicy-${var.cluster_name}"
  policy = templatefile("${path.module}/files/karpenter-eks-integration-policy.json.tftpl", {
    partition    = local.karpenter_partition
    region       = local.karpenter_region
    account_id   = local.karpenter_account_id
    cluster_name = var.cluster_name
  })
}

resource "aws_iam_policy" "karpenter_interruption" {
  count = var.enable_karpenter ? 1 : 0
  name  = "KarpenterControllerInterruptionPolicy-${var.cluster_name}"
  policy = templatefile("${path.module}/files/karpenter-interruption-policy.json.tftpl", {
    interruption_queue_arn = aws_sqs_queue.karpenter_interruption[0].arn
  })
}

resource "aws_iam_policy" "karpenter_zonal_shift" {
  count = var.enable_karpenter ? 1 : 0
  name  = "KarpenterControllerZonalShiftPolicy-${var.cluster_name}"
  policy = templatefile("${path.module}/files/karpenter-zonal-shift-policy.json.tftpl", {
    partition    = local.karpenter_partition
    region       = local.karpenter_region
    account_id   = local.karpenter_account_id
    cluster_name = var.cluster_name
  })
}

resource "aws_iam_policy" "karpenter_resource_discovery" {
  count = var.enable_karpenter ? 1 : 0
  name  = "KarpenterControllerResourceDiscoveryPolicy-${var.cluster_name}"
  policy = templatefile("${path.module}/files/karpenter-resource-discovery-policy.json.tftpl", {
    partition  = local.karpenter_partition
    region     = local.karpenter_region
    account_id = local.karpenter_account_id
  })
}

# --- IRSA role controller Karpenter - service account default Karpenter
#     adalah "karpenter" di namespace "kube-system".
data "aws_iam_policy_document" "karpenter_controller_assume" {
  count = var.enable_karpenter ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.cluster.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:karpenter"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "karpenter_controller" {
  count              = var.enable_karpenter ? 1 : 0
  name               = "${var.cluster_name}-karpenter-controller-role"
  assume_role_policy = data.aws_iam_policy_document.karpenter_controller_assume[0].json
}

resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  for_each = var.enable_karpenter ? {
    node_lifecycle     = aws_iam_policy.karpenter_node_lifecycle[0].arn
    iam_integration    = aws_iam_policy.karpenter_iam_integration[0].arn
    eks_integration    = aws_iam_policy.karpenter_eks_integration[0].arn
    interruption       = aws_iam_policy.karpenter_interruption[0].arn
    zonal_shift        = aws_iam_policy.karpenter_zonal_shift[0].arn
    resource_discovery = aws_iam_policy.karpenter_resource_discovery[0].arn
  } : {}

  role       = aws_iam_role.karpenter_controller[0].name
  policy_arn = each.value
}
