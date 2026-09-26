variable "aws_region" {
  type    = string
  default = "ap-southeast-3"
}

variable "name_prefix" {
  type    = string
  default = "tutd3-dev"
}

variable "enable_eks" {
  description = "Set false untuk sementara tidak membuat cluster EKS (biar hemat biaya saat belum dipakai)"
  type        = bool
  default     = true
}

variable "enable_ec2" {
  description = "Set false untuk sementara tidak membuat instance EC2 contoh"
  type        = bool
  default     = true
}

variable "ec2_key_name" {
  description = "Nama EC2 key pair untuk SSH ke instance contoh. Kosongkan kalau belum punya."
  type        = string
  default     = null
}

variable "eks_node_instance_types" {
  description = "Instance type untuk EKS worker node. Default t3.micro karena akun AWS ini masih ada pembatasan Free Tier (tipe non-free-tier ditolak saat launch). Ganti ke t3.medium/lainnya setelah pembatasan itu dilepas."
  type        = list(string)
  default     = ["t3.micro"]
}

variable "app_bucket_name" {
  description = "Nama S3 bucket untuk kebutuhan aplikasi (harus unik global)"
  type        = string
  default     = "tutd3-dev-app-094983223261"
}
