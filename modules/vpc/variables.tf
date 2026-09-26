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
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Daftar CIDR untuk subnet privat (satu per AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
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

variable "tags" {
  description = "Tag tambahan untuk semua resource"
  type        = map(string)
  default     = {}
}
