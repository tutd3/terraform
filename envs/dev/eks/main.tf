module "eks" {
  source = "../../../modules/eks"

  cluster_name       = "${var.name_prefix}-eks"
  kubernetes_version = var.kubernetes_version
  subnet_ids = concat(
    data.terraform_remote_state.vpc.outputs.public_subnet_ids,
    data.terraform_remote_state.vpc.outputs.private_subnet_ids,
  )
  node_instance_types = var.node_instance_types
  small_instance_mode = true # t3.micro - lihat catatan di modules/eks/variables.tf

  tags = {
    Environment = "dev"
  }
}
