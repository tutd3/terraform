variable "aws_region" {
  type    = string
  default = "ap-southeast-3"
}

variable "name_prefix" {
  type    = string
  default = "tutd3-staging"
}

variable "console_login_pgp_key" {
  description = "PGP public key (base64) untuk enkripsi password console login. Kosongkan kalau user cuma butuh akses programatik, atau belum ada user."
  type        = string
  default     = null
}
