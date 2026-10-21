# Modul EKS: cluster managed + node group + dukungan PVC (Persistent Volume
# Claim) lewat EBS CSI driver, supaya pod di Kubernetes bisa minta storage
# yang otomatis dibuatkan EBS volume oleh AWS.

# --- IAM role untuk EKS control plane ---
data "aws_iam_policy_document" "cluster_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume.json
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# --- EKS Cluster ---
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = var.enable_public_access
    endpoint_private_access = true
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]

  tags = var.tags
}

# --- OIDC provider untuk cluster ini (dibutuhkan IRSA: IAM Role for Service Account) ---
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
}

# --- IAM role untuk worker nodes ---
data "aws_iam_policy_document" "node_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

locals {
  node_subnet_ids = length(var.node_subnet_ids) > 0 ? var.node_subnet_ids : var.subnet_ids
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-default"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = local.node_subnet_ids

  instance_types = var.node_instance_types
  capacity_type  = var.node_capacity_type
  disk_size      = var.node_disk_size_gb

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
  ]

  tags = var.tags
}

# --- EBS CSI driver: dibutuhkan supaya PersistentVolumeClaim di Kubernetes
#     bisa otomatis membuat EBS volume di AWS ---
data "aws_iam_policy_document" "ebs_csi_assume" {
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
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "${var.cluster_name}-ebs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = aws_iam_role.ebs_csi.arn
  resolve_conflicts_on_update = "OVERWRITE"

  # Instance kecil (mis. t3.micro) tidak cukup slot pod/memori untuk 2 replica
  # controller. 1 replica cukup untuk dev, tidak butuh HA.
  configuration_values = jsonencode({
    controller = {
      replicaCount = var.small_instance_mode ? 1 : 2
    }
  })

  depends_on = [aws_eks_node_group.default]
}

locals {
  # - Prefix delegation: menaikkan drastis jumlah IP (dan jumlah pod) yang
  #   bisa dijadwalkan per node, penting untuk instance kecil seperti
  #   t3.micro yang defaultnya cuma muat segelintir pod (dibatasi jumlah
  #   ENI/IP, bukan CPU/RAM).
  # - enableNetworkPolicy: cuma MENGAKTIFKAN KAPASITAS enforce Kubernetes
  #   NetworkPolicy (vpc-cni sudah native support, tidak perlu Calico/Cilium
  #   tambahan). Tidak ada efek langsung ke traffic yang ada sekarang - baru
  #   berlaku begitu ada objek NetworkPolicy yang dibuat (lewat kubectl,
  #   bukan Terraform).
  vpc_cni_config = merge(
    var.small_instance_mode ? { env = { ENABLE_PREFIX_DELEGATION = "true" } } : {},
    var.enable_network_policy ? { enableNetworkPolicy = "true" } : {},
  )
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_update = "OVERWRITE"
  configuration_values        = length(local.vpc_cni_config) > 0 ? jsonencode(local.vpc_cni_config) : null
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  resolve_conflicts_on_update = "OVERWRITE"

  configuration_values = jsonencode({
    replicaCount = var.small_instance_mode ? 1 : 2
  })

  depends_on = [aws_eks_node_group.default]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_update = "OVERWRITE"
}

# --- Akses Kubernetes API untuk principal lain (selain role CI yang bikin
#     cluster, yang otomatis dapat akses admin) ---
#
# SENGAJA 1 resource gabungan (bukan 2 resource terpisah admin/viewer) -
# supaya pindah tier (mis. readonly -> admin) itu jadi UPDATE policy_arn di
# resource yang SAMA, bukan destroy di satu resource + create di resource
# lain. Kalau dipisah, Terraform bisa menjalankan create (tier baru) sebelum
# destroy (tier lama) benar-benar selesai di sisi AWS, kena
# "ResourceInUseException: already in use" (pernah kejadian).
locals {
  # admin menang kalau 1 ARN ada di dua-duanya (seharusnya tidak terjadi,
  # tapi ini jaga-jaga).
  eks_access_policy_by_principal = merge(
    { for arn in var.viewer_principal_arns : arn => "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy" },
    { for arn in var.admin_principal_arns : arn => "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" },
  )
}

resource "aws_eks_access_entry" "this" {
  for_each      = local.eks_access_policy_by_principal
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.key
}

resource "aws_eks_access_policy_association" "this" {
  for_each      = local.eks_access_policy_by_principal
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.key
  policy_arn    = each.value

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.this]
}

# --- Rule tambahan di security group cluster (auto-dibuat & dipakai bareng
#     oleh control plane + semua worker node) ---
locals {
  cluster_sg_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

# Semua TCP antar-resource di dalam VPC yang sama (mis. VPN server yang akan
# dibuat di VPC ini, service lain yang perlu akses node/pod langsung).
resource "aws_vpc_security_group_ingress_rule" "intra_vpc_tcp" {
  security_group_id = local.cluster_sg_id
  description       = "Semua TCP dari dalam VPC (${var.vpc_cidr})"
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = 65535
  cidr_ipv4         = var.vpc_cidr
}

# ICMP type 3 code 4 (Fragmentation Needed) - wajib untuk Path MTU Discovery,
# bukan celah keamanan (cuma pesan error "paket kebesaran", bukan jalur masuk).
resource "aws_vpc_security_group_ingress_rule" "icmp_frag_needed" {
  security_group_id = local.cluster_sg_id
  description       = "ICMP type 3 code 4 (Fragmentation Needed / Path MTU Discovery)"
  ip_protocol       = "icmp"
  from_port         = 3
  to_port           = 4
  cidr_ipv4         = "0.0.0.0/0"
}

# Port 80/443 publik - dibutuhkan kalau ada NLB/ingress controller yang
# terusin traffic internet langsung ke node (pola: NLB -> NodePort/hostNetwork).
resource "aws_vpc_security_group_ingress_rule" "http_public" {
  count             = var.node_sg_allow_web_public ? 1 : 0
  security_group_id = local.cluster_sg_id
  description       = "HTTP publik (traffic dari NLB/ingress controller)"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "https_public" {
  count             = var.node_sg_allow_web_public ? 1 : 0
  security_group_id = local.cluster_sg_id
  description       = "HTTPS publik (traffic dari NLB/ingress controller)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}
