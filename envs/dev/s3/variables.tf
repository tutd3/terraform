variable "aws_region" {
  type    = string
  default = "ap-southeast-3"
}

variable "app_bucket_name" {
  description = "Nama S3 bucket untuk kebutuhan aplikasi (harus unik global)"
  type        = string
  default     = "tutd3-dev-app-094983223261"
}

variable "test1_cempaka_bucket_name" {
  type    = string
  default = "test1-cempaka"
}
