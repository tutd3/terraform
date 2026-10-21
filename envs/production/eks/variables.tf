variable "aws_region" {
  type    = string
  default = "ap-southeast-3"
}

variable "name_prefix" {
  type    = string
  default = "tutd3-production"
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

variable "admin_principal_arns" {
  description = "IAM principal (selain role CI) yang diberi akses admin Kubernetes API, mis. root user akun AWS supaya bisa lihat resource di AWS Console."
  type        = list(string)
  default     = ["arn:aws:iam::094983223261:root"]
}

variable "enable_public_access" {
  description = "false (default) = API server cuma bisa diakses dari dalam VPC (lewat VPN nanti). Ganti ke true kalau butuh akses internet langsung sebelum VPN jadi (tidak disarankan untuk production)."
  type        = bool
  default     = false
}

variable "node_disk_size_gb" {
  description = "Ukuran EBS root volume tiap worker node (GB)."
  type        = number
  default     = 100
}

variable "node_availability_zones" {
  description = "AZ untuk worker node EKS - isi 1 AZ (mis. [\"ap-southeast-3a\"]) untuk hemat biaya, atau 2+ untuk HA lebih tinggi. Cluster control plane TETAP multi-AZ (wajib dari AWS) apa pun isi ini - yang dibatasi cuma node-nya."
  type        = list(string)
  default     = ["ap-southeast-3a"]
}
