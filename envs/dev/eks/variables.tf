variable "aws_region" {
  type    = string
  default = "ap-southeast-3"
}

variable "name_prefix" {
  type    = string
  default = "tutd3-dev"
}

variable "kubernetes_version" {
  type    = string
  default = "1.36"
}

variable "node_instance_types" {
  description = "Instance type untuk EKS worker node. Default t3.micro karena akun AWS ini masih ada pembatasan Free Tier (tipe non-free-tier ditolak saat launch). Ganti ke t3.medium/lainnya setelah pembatasan itu dilepas."
  type        = list(string)
  default     = ["t3.micro"]
}
