variable "aws_region" {
  type    = string
  default = "ap-southeast-3"
}

variable "name_prefix" {
  type    = string
  default = "wetech-staging"
}

# Nilai readonly_users/admin_users TIDAK di-default di sini - isinya ada di
# users.auto.tfvars (file terpisah khusus data, lihat README.md bagian "IAM
# user & akses"). Terraform otomatis membaca *.auto.tfvars tanpa perlu flag
# apa pun. Dipisah dari file ini supaya definisi variable (type/description)
# tidak campur dengan datanya.
variable "readonly_users" {
  description = "Daftar nama IAM user readonly - isi lewat users.auto.tfvars, bukan default di sini."
  type        = list(string)
  default     = []
}

variable "admin_users" {
  description = "Daftar nama IAM user admin - isi lewat users.auto.tfvars, bukan default di sini."
  type        = list(string)
  default     = []
}

variable "console_login_pgp_key" {
  description = "PGP public key (base64) untuk enkripsi password console login. Kosongkan kalau user cuma butuh akses programatik, atau belum ada user."
  type        = string
  default     = null
}
