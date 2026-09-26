module "vpc" {
  source = "../../modules/vpc"

  name        = var.name_prefix
  cluster_tag = var.enable_eks ? "${var.name_prefix}-eks" : ""

  tags = {
    Environment = "dev"
  }
}

module "app_bucket" {
  source = "../../modules/s3"

  bucket_name = var.app_bucket_name

  tags = {
    Environment = "dev"
  }
}

module "test1_cempaka_bucket" {
  source = "../../modules/s3"

  bucket_name = "test1-cempaka"

  tags = {
    Environment = "dev"
  }
}

module "example_ec2" {
  count  = var.enable_ec2 ? 1 : 0
  source = "../../modules/ec2"

  name      = "${var.name_prefix}-example"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnet_ids[0]
  key_name  = var.ec2_key_name

  ingress_rules = [
    {
      description = "SSH dari mana saja (ganti ke IP kamu saja untuk produksi)"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Environment = "dev"
  }
}

module "eks" {
  count  = var.enable_eks ? 1 : 0
  source = "../../modules/eks"

  cluster_name        = "${var.name_prefix}-eks"
  subnet_ids          = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  node_instance_types = var.eks_node_instance_types

  tags = {
    Environment = "dev"
  }
}
