variable "name" {
  description = "Prefix nama untuk semua resource VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block untuk VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Daftar CIDR untuk subnet publik (satu per AZ)"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Daftar CIDR untuk subnet privat (satu per AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "enable_nat_gateway" {
  description = "Aktifkan NAT gateway supaya subnet privat bisa akses internet keluar (dibutuhkan node EKS untuk pull image, dll). Berbayar per jam + per GB."
  type        = bool
  default     = true
}

variable "cluster_tag" {
  description = "Nama cluster EKS yang akan pakai VPC ini, dipakai untuk tag auto-discovery subnet. Kosongkan jika VPC tidak dipakai EKS."
  type        = string
  default     = ""
}

# Route tambahan di luar default (public: 0.0.0.0/0 lewat internet gateway,
# private: 0.0.0.0/0 lewat NAT gateway kalau enable_nat_gateway) - mis. untuk
# VPN server (network_interface_id), VPC peering (vpc_peering_connection_id),
# atau Transit Gateway (transit_gateway_id).
#
# SENGAJA pakai dynamic "route" di resource aws_route_table yang sama
# (lihat main.tf), BUKAN resource aws_route terpisah - AWS provider
# Terraform memperingatkan eksplisit: route inline di aws_route_table yang
# dicampur dengan resource aws_route terpisah ke tabel yang sama akan
# rebutan kontrol dan menghasilkan diff yang tidak pernah bersih.
#
# Tiap elemen WAJIB isi cidr_block + TEPAT SATU target (field lain
# dikosongkan/null) - AWS menolak route dengan 0 atau lebih dari 1 target.
variable "additional_public_routes" {
  description = "Route tambahan untuk route table PUBLIC, selain default ke internet gateway."
  type = list(object({
    cidr_block                = string
    gateway_id                = optional(string)
    nat_gateway_id            = optional(string)
    transit_gateway_id        = optional(string)
    vpc_peering_connection_id = optional(string)
    network_interface_id      = optional(string)
  }))
  default = []
}

variable "additional_private_routes" {
  description = "Route tambahan untuk route table PRIVATE, selain default ke NAT gateway (kalau enable_nat_gateway=true)."
  type = list(object({
    cidr_block                = string
    gateway_id                = optional(string)
    nat_gateway_id            = optional(string)
    transit_gateway_id        = optional(string)
    vpc_peering_connection_id = optional(string)
    network_interface_id      = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Tag tambahan untuk semua resource"
  type        = map(string)
  default     = {}
}
