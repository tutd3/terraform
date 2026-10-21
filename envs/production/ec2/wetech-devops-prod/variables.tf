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
  type    = string
  default = "m6i.xlarge"
}

variable "ami_id" {
  description = "AMI ID spesifik untuk instance ini. Kosongkan (null) untuk otomatis pakai Amazon Linux 2023 terbaru (non-minimal, sudah ada SSM Agent) - lihat modules/ec2."
  type        = string
  default     = null
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
