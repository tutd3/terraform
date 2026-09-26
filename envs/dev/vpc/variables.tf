variable "aws_region" {
  type    = string
  default = "ap-southeast-3"
}

variable "name_prefix" {
  type    = string
  default = "tutd3-dev"
}

variable "tag_for_eks" {
  description = "Set true supaya subnet ditag untuk auto-discovery EKS (stack eks/ pakai VPC ini)"
  type        = bool
  default     = true
}
