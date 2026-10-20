variable "aws_region" {
  type    = string
  default = "ap-southeast-3"
}

variable "name_prefix" {
  type    = string
  default = "tutd3-production"
}

variable "readonly_users" {
  description = "Daftar nama IAM user readonly. Kosongkan dulu, isi kapan saja lewat PR."
  type        = list(string)
  default     = []
}

variable "admin_users" {
  description = "Daftar nama IAM user admin. Kosongkan dulu, isi kapan saja lewat PR."
  type        = list(string)
  default     = []
}

variable "console_login_pgp_key" {
  description = "PGP public key (base64) untuk enkripsi password console login. Kosongkan kalau user cuma butuh akses programatik, atau belum ada user."
  type        = string
  default     = null
}
