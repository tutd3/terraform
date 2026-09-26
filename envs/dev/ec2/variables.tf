variable "aws_region" {
  type    = string
  default = "ap-southeast-3"
}

variable "name_prefix" {
  type    = string
  default = "tutd3-dev"
}

variable "ec2_key_name" {
  description = "Nama EC2 key pair untuk SSH. Kosongkan kalau belum punya."
  type        = string
  default     = null
}
