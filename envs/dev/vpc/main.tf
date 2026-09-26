module "vpc" {
  source = "../../../modules/vpc"

  name        = var.name_prefix
  cluster_tag = var.tag_for_eks ? "${var.name_prefix}-eks" : ""

  tags = {
    Environment = "dev"
  }
}
