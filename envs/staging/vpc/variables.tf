variable "aws_region" {
  type    = string
  default = "ap-southeast-3"
}

variable "name_prefix" {
  type    = string
  default = "tutd3-staging"
}

variable "tag_for_eks" {
  description = "Set true supaya subnet ditag untuk auto-discovery EKS (stack eks/ pakai VPC ini)"
  type        = bool
  default     = true
}

# Disamakan dengan production (lihat envs/production/vpc/variables.tf) -
# kalau nanti vpc production/staging perlu di-peering atau konek lewat
# VPN/Transit Gateway, salah satunya WAJIB diganti ke range yang tidak
# tumpang tindih dulu sebelum itu dibuat (AWS menolak peering CIDR yang
# sama/overlap).
variable "vpc_cidr" {
  type    = string
  default = "10.103.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.103.0.0/24", "10.103.1.0/24", "10.103.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.103.10.0/24", "10.103.11.0/24", "10.103.12.0/24"]
}
