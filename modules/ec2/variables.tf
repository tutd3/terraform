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
  description = "AMI ID spesifik - bebas OS apa pun (distro Linux lain, Windows Server, AMI custom/marketplace, dll), tidak terbatas Amazon Linux. Kosongkan (null) untuk otomatis pakai Amazon Linux 2023 terbaru (non-minimal, sudah ada SSM Agent)."
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
  # AMI Amazon Linux 2023 default butuh volume >= 30GB (batas dari snapshot-nya).
  # Untuk AMI Windows biasanya butuh lebih besar lagi (minimal snapshot AMI-nya
  # bisa 30-50GB+, cek AMI yang dipakai).
  type    = number
  default = 30
}

variable "root_volume_type" {
  description = "Tipe EBS root volume: gp3 (default, SSD umum/elastis), gp2 (SSD lama), io1/io2 (SSD performa tinggi, butuh IOPS tinggi & konsisten), st1 (HDD throughput-optimized, untuk data besar jarang diakses random), sc1 (HDD paling murah, jarang diakses)."
  type        = string
  default     = "gp3"
}

variable "root_volume_iops" {
  description = "IOPS root volume. Kosongkan (null) untuk default AWS (gp3: 3000). WAJIB diisi untuk io1/io2 (AWS tidak kasih default). Tidak berlaku untuk st1/sc1."
  type        = number
  default     = null
}

variable "root_volume_throughput" {
  description = "Throughput root volume dalam MB/s. HANYA berlaku untuk volume_type gp3 (AWS menolak kalau diisi untuk tipe lain). Kosongkan (null) untuk default AWS (125 MB/s)."
  type        = number
  default     = null
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
