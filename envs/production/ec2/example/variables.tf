variable "aws_region" {
  type    = string
  default = "ap-southeast-3"
}

variable "name_prefix" {
  type    = string
  default = "tutd3-production"
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
  default     = ""
}
