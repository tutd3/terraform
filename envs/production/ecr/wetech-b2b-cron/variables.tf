variable "aws_region" {
  type    = string
  default = "ap-southeast-3"
}

variable "repository_name" {
  description = "Nama ECR repository."
  type        = string
  default     = "wetech-b2b-cron"
}
