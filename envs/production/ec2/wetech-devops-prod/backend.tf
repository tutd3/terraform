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

# Baca ARN repository ECR - dibutuhkan untuk scope policy push image di
# instance ini (lihat main.tf, inline_iam_policies).
data "terraform_remote_state" "ecr" {
  backend = "s3"

  config = {
    bucket = "tutd3-terraform-state-094983223261"
    key    = "envs/production/ecr/wetech-b2b-cron/terraform.tfstate"
    region = "ap-southeast-3"
  }
}
