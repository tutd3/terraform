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
    key          = "envs/production/ec2/wetech-devops-prod/terraform.tfstate"
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
      Stack       = "ec2/wetech-devops-prod"
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

# Dibutuhkan untuk bangun ARN wildcard semua ECR repository di akun &
# region ini (lihat main.tf, inline_iam_policies) - termasuk repository
# yang dibuat MANUAL (bukan lewat Terraform), bukan cuma yang di-manage di
# envs/production/ecr/*.
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
