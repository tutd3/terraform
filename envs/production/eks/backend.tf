terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "tutd3-terraform-state-094983223261"
    key          = "envs/production/eks/terraform.tfstate"
    region       = "ap-southeast-3"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "production"
      ManagedBy   = "terraform"
      Project     = "wetech"
      Stack       = "eks"
    }
  }
}

# Baca output dari stack vpc/ (state terpisah, di-manage independen)
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "tutd3-terraform-state-094983223261"
    key    = "envs/production/vpc/terraform.tfstate"
    region = "ap-southeast-3"
  }
}

# Baca output dari stack iam/ (daftar user readonly -> dikasih akses view ke
# Kubernetes API, lihat main.tf)
data "terraform_remote_state" "iam" {
  backend = "s3"

  config = {
    bucket = "tutd3-terraform-state-094983223261"
    key    = "envs/production/iam/terraform.tfstate"
    region = "ap-southeast-3"
  }
}
