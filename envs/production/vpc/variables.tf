variable "aws_region" {
  type    = string
  default = "ap-southeast-3"
}

variable "name_prefix" {
  type    = string
  default = "tutd3-production"
}

variable "tag_for_eks" {
  description = "Set true supaya subnet ditag untuk auto-discovery EKS (stack eks/ pakai VPC ini)"
  type        = bool
  default     = true
}

# Override dari default module (10.0.0.0/16 dkk) - dipakai kalau butuh range
# IP lain, mis. supaya tidak tumpang tindih dengan VPC lain yang nanti mau
# di-peering/VPN. public_subnet_cidrs & private_subnet_cidrs WAJIB ikut
# diganti konsisten dengan vpc_cidr - keduanya harus berada DI DALAM range
# vpc_cidr, kalau tidak "terraform apply" akan gagal (AWS mewajibkan subnet
# CIDR adalah bagian dari VPC CIDR-nya).
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
