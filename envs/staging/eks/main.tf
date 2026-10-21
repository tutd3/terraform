locals {
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
  node_subnet_ids      = local.node_subnet_ids
  node_instance_types  = var.node_instance_types
  small_instance_mode  = true # t3.micro - lihat catatan di modules/eks/variables.tf
  node_disk_size_gb    = var.node_disk_size_gb
  vpc_cidr             = data.terraform_remote_state.vpc.outputs.vpc_cidr
  admin_principal_arns = var.admin_principal_arns
  enable_public_access = var.enable_public_access

  tags = {
    Environment = "staging"
  }
}
