variable "aws_region" {
  type    = string
  default = "ap-southeast-3"
}

variable "service_name" {
  description = "Nama service untuk instance ini - dipakai di naming standar wetech-<service>-<environment>."
  type        = string
  default     = "devops"
}

variable "instance_type" {
  description = "Instance type - default t3.micro karena akun ini masih ada pembatasan Free Tier (tipe non-free-tier ditolak saat launch)."
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID spesifik untuk instance ini. Kosongkan (null) untuk otomatis pakai Amazon Linux 2023 terbaru (non-minimal, sudah ada SSM Agent) - lihat modules/ec2. Sekarang: Ubuntu 26.04 (Canonical, resmi, sudah ada SSM Agent bawaan)."
  type        = string
  default     = "ami-039f9d16a13e3a0a7"
}

variable "ec2_key_name" {
  description = "Nama EC2 key pair untuk SSH. Kosongkan kalau belum punya."
  type        = string
  default     = null
}

variable "public" {
  description = "true = taruh di subnet publik (dapat IP publik, bisa diakses dari internet kalau security group mengizinkan). false = subnet privat (cuma bisa diakses dari dalam VPC, tetap bisa akses keluar lewat NAT gateway)."
  type        = bool
  default     = true
}

variable "availability_zone" {
  description = "Zona spesifik, mis. \"ap-southeast-3b\". Kosongkan untuk otomatis pakai AZ pertama yang tersedia."
  type        = string
  default     = "ap-southeast-3a"
}
