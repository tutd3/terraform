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
  type    = string
  default = null
}

variable "root_volume_size_gb" {
  type    = number
  default = 20
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
