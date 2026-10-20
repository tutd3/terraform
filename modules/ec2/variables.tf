variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID spesifik. Kosongkan (null) untuk otomatis pakai Amazon Linux 2023 terbaru."
  type        = string
  default     = null
}

variable "key_name" {
  description = "Nama EC2 key pair untuk akses SSH. Kosongkan kalau tidak butuh akses SSH langsung."
  type        = string
  default     = null
}

variable "iam_instance_profile_name" {
  description = "Nama instance profile IAM yang SUDAH ADA untuk dipakai instance ini. Diabaikan kalau enable_ssm=true (modul bikin & pakai instance profile sendiri untuk SSM)."
  type        = string
  default     = null
}

variable "enable_ssm" {
  description = "Set true (default) supaya instance ini otomatis bisa diakses lewat AWS Systems Manager Session Manager (tidak perlu SSH key/port 22 terbuka sama sekali) - modul bikin sendiri IAM role+instance profile dengan policy AmazonSSMManagedInstanceCore. Set false untuk pakai iam_instance_profile_name sendiri (atau tidak pakai profile sama sekali)."
  type        = bool
  default     = true
}

variable "root_volume_size_gb" {
  # AMI Amazon Linux 2023 default butuh volume >= 30GB (batas dari snapshot-nya)
  type    = number
  default = 30
}

variable "ingress_rules" {
  description = "Daftar rule ingress security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
