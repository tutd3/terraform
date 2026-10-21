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
    key          = "envs/staging/ec2/example/terraform.tfstate"
    region       = "ap-southeast-3"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "staging"
      ManagedBy   = "terraform"
      Project     = "wetech"
      Stack       = "ec2/example"
    }
  }
}

# Baca output dari stack vpc/ (state terpisah, di-manage independen)
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "tutd3-terraform-state-094983223261"
    key    = "envs/staging/vpc/terraform.tfstate"
    region = "ap-southeast-3"
  }
}
