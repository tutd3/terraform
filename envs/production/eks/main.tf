locals {
  # Node HANYA di subnet PRIVAT pada AZ yang dipilih (var.node_availability_zones)
  # - private_subnets_by_az sudah ada sebagai output vpc, tidak perlu lookup lagi.
  node_subnet_ids = [
    for az in var.node_availability_zones :
    data.terraform_remote_state.vpc.outputs.private_subnets_by_az[az]
  ]
}

module "eks" {
  source = "../../../modules/eks"

  cluster_name       = "${var.name_prefix}-eks"
  kubernetes_version = var.kubernetes_version
  subnet_ids = concat(
    data.terraform_remote_state.vpc.outputs.public_subnet_ids,
    data.terraform_remote_state.vpc.outputs.private_subnet_ids,
  )
  node_subnet_ids         = local.node_subnet_ids
  node_instance_types     = var.node_instance_types
  small_instance_mode     = true # t3.micro - Free Tier, addon turun ke 1 replica + VPC CNI prefix delegation
  node_group_system_taint = true # node group default khusus addon sistem (CoreDNS, EBS CSI controller)
  node_disk_size_gb       = var.node_disk_size_gb
  vpc_cidr                = data.terraform_remote_state.vpc.outputs.vpc_cidr
  enable_network_policy   = true
  enable_public_access    = var.enable_public_access
  admin_principal_arns = concat(
    var.admin_principal_arns, # mis. root user, lihat variables.tf
    values(data.terraform_remote_state.iam.outputs.admin_user_arns),
    [data.terraform_remote_state.iam.outputs.eks_cluster_role_arn],
  )
  viewer_principal_arns = values(data.terraform_remote_state.iam.outputs.readonly_user_arns)

  tags = {
    Environment = "production"
  }
}

# Izin tambahan untuk role control plane cluster ini, supaya bisa bikin/kelola
# AWS Load Balancer dari resource Kubernetes (mis. Service type=LoadBalancer).
data "aws_iam_policy_document" "cluster_load_balancer_access" {
  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:*",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:DescribeSecurityGroups",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cluster_load_balancer_access" {
  name   = "wetech-service-kubernetes-prod-load-balance-access"
  policy = data.aws_iam_policy_document.cluster_load_balancer_access.json
}

resource "aws_iam_role_policy_attachment" "cluster_load_balancer_access" {
  role       = module.eks.cluster_role_name
  policy_arn = aws_iam_policy.cluster_load_balancer_access.arn
}
