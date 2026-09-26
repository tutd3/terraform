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
    key          = "envs/dev/vpc/terraform.tfstate"
    region       = "ap-southeast-3"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dev"
      ManagedBy   = "terraform"
      Project     = "tutd3-infra"
      Stack       = "vpc"
    }
  }
}
