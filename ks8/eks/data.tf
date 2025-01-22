data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "http" "wait_for_cluster" {
  count          = var.manage_aws_auth ? 1 : 0
  url            = format("%s/healthz", module.cluster_control_plane.endpoint)
  ca_certificate = base64decode(module.cluster_control_plane.certificate_authority_data)
  timeout        = 300

  depends_on = [
    module.cluster_control_plane,
    # aws_security_group_rule.cluster_private_access_sg_source,
    # aws_security_group_rule.cluster_private_access_cidrs_source,
  ]
}

data "aws_eks_cluster" "default" {
  name = module.cluster_control_plane.id
}

data "aws_eks_cluster_auth" "default" {
  name = module.cluster_control_plane.id
}