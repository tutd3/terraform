module "vpc" {
  source = "../../../modules/vpc"

  name                      = var.name_prefix
  vpc_cidr                  = var.vpc_cidr
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_subnet_cidrs      = var.private_subnet_cidrs
  additional_public_routes  = var.additional_public_routes
  additional_private_routes = var.additional_private_routes
  cluster_tag               = var.tag_for_eks ? "${var.name_prefix}-eks" : ""

  tags = {
    Environment = "staging"
  }
}
