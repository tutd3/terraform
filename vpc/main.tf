provider "aws" {
  region = "ap-southeast-1"
  assume_role {
    role_arn     = var.role_arn != "" ? var.role_arn : ""
  }
}
