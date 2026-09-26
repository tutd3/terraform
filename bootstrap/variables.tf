variable "aws_region" {
  description = "Region AWS tempat semua resource dibuat"
  type        = string
  default     = "ap-southeast-3"
}

variable "state_bucket_name" {
  description = "Nama S3 bucket untuk menyimpan Terraform state (harus unik secara global)"
  type        = string
  default     = "tutd3-terraform-state-094983223261"
}

variable "role_name" {
  description = "Nama IAM role yang di-assume oleh GitHub Actions"
  type        = string
  default     = "gh-actions-terraform"
}

variable "github_org" {
  description = "Nama org/user GitHub"
  type        = string
  default     = "tutd3"
}

variable "github_repo" {
  description = "Nama repo GitHub"
  type        = string
  default     = "terraform"
}
