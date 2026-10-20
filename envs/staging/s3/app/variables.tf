variable "aws_region" {
  type    = string
  default = "ap-southeast-3"
}

variable "bucket_name" {
  description = "Nama S3 bucket untuk kebutuhan aplikasi (harus unik global)"
  type        = string
  default     = "tutd3-staging-app-094983223261"
}
