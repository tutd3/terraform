################################################################################
# IAM Role for EKS Worker nodes
# - assign policy 'AmazonEKSWorkerNodePolicy', 'AmazonEKS_CNI_Policy', and 'AmazonEC2ContainerRegistryReadOnly'
################################################################################
resource "aws_iam_role" "worker_node" {
  name = "${var.cluster_name}-worker-nodes-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_instance_profile" "worker_node" {
  name = format("iam-%s-worker-nodes", var.cluster_name)
  role = aws_iam_role.worker_node.id

  path = "/"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker_node.name
}

resource "aws_iam_role_policy_attachment" "cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker_node.name
}

resource "aws_iam_role_policy_attachment" "registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker_node.name
}

################################################################################
# Cluster worker nodes
################################################################################
locals {
  worker_subnet_ids = {
    public   = var.public_subnet_ids
    public2  = var.public_subnet_ids2
    public3  = var.public_subnet_ids3
    private  = var.private_subnet_ids
    private2 = var.private_subnet_ids2
    private3 = var.private_subnet_ids3
  }
  cluster_output_worker_nodes_resources               = [for v in aws_eks_node_group.main : v.resources]
  cluster_output_worker_nodes_autoscalling_group      = [for v in local.cluster_output_worker_nodes_resources : v[0].autoscaling_groups.*]
  cluster_output_worker_nodes_autoscalling_group_name = flatten([for v in local.cluster_output_worker_nodes_autoscalling_group : v.*.name])

  worker_nodes = var.worker_nodes

  list_node_groups_tags = flatten([
    for name, node_group in var.worker_nodes : [
      for k, v in node_group.tags: {
        "${name}-${k}" = {
          node_group = name,
          tag_key = k,
          tag_value = v
        }
      }
    ]
  ])

  map_node_groups_tags = {
    for item in local.list_node_groups_tags: keys(item)[0] => values(item)[0]
  }
}

resource "aws_launch_template" "main" {
  for_each =  var.launch_template_variable
  name     = "${each.key}-${var.cluster_name}-launch-template"
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = each.value.volume_size
      volume_type           = each.value.volume_type
      delete_on_termination = true
    }
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name         = var.cluster_name
  version              = try(each.value.k8s_version, var.k8s_version)
  node_role_arn        = aws_iam_role.worker_node.arn

  for_each             = var.worker_nodes
  node_group_name      = each.key
  subnet_ids           = lookup(local.worker_subnet_ids, each.value.subnet_type)
  instance_types       = each.value.instance_types
  capacity_type        = each.value.capacity_type
  disk_size            = var.use_custom_launch_template ? null : each.value.disk_size
  force_update_version = each.value.force_update_version
  labels               = each.value.kubernetes_labels
  tags                 = each.value.tags

  dynamic "launch_template" {
    for_each = lookup(each.value, "volume_type", "") != "" && var.use_custom_launch_template ? [1] : []
    content {
      id      = aws_launch_template.main[each.value.volume_type].id
      version = aws_launch_template.main[each.value.volume_type].default_version
    }
  }

  dynamic "taint" {
    for_each = lookup(each.value, "taint", false) ? [each.value] : []
    content {
      key = lookup(taint.value, "taint_key", "eks.amazonaws.com/capacityType")
      value = lookup(taint.value, "taint_value", "SPOT")
      effect = lookup(taint.value, "taint_effect", "NO_SCHEDULE")
    }
  }

  scaling_config {
    desired_size = each.value.scaling_config.desired_size
    max_size     = each.value.scaling_config.max_size
    min_size     = each.value.scaling_config.min_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker,
    aws_iam_role_policy_attachment.cni,
    aws_iam_role_policy_attachment.registry,
  ]

  # ignore desired_size so when applying not override current desired managed by cluster autoscaler
  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size
    ]
  }
}

resource "aws_autoscaling_group_tag" "instance_tags" {
  for_each = local.map_node_groups_tags

  autoscaling_group_name = aws_eks_node_group.main[each.value.node_group].resources[0].autoscaling_groups[0].name

  tag {
    key   = each.value.tag_key
    value = each.value.tag_value
    propagate_at_launch = true
  }
}

################################################################################
# EKS Addons
################################################################################
resource "aws_eks_addon" "this" {
  # Not supported on outposts
  for_each = { for k, v in var.cluster_addons : k => v }

  cluster_name = var.cluster_name
  addon_name   = try(each.value.name, each.key)

  addon_version            = try(each.value.addon_version, data.aws_eks_addon_version.this[each.key].version)
  preserve                 = try(each.value.preserve, null)
  resolve_conflicts        = try(each.value.resolve_conflicts, "OVERWRITE")
  service_account_role_arn = try(each.value.service_account_role_arn, null)

  timeouts {
    create = try(each.value.timeouts.create, var.cluster_addons_timeouts.create, null)
    update = try(each.value.timeouts.update, var.cluster_addons_timeouts.update, null)
    delete = try(each.value.timeouts.delete, var.cluster_addons_timeouts.delete, null)
  }

  depends_on = [
    aws_eks_node_group.main
  ]

  tags = var.cluster_tags
}

data "aws_eks_addon_version" "this" {
  for_each = { for k, v in var.cluster_addons : k => v }

  addon_name         = try(each.value.name, each.key)
  kubernetes_version = coalesce(var.k8s_version, var.k8s_version)
  most_recent        = try(each.value.most_recent, null)
}
