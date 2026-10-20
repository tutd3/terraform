variable "name_prefix" {
  description = "Prefix nama untuk group IAM, mis. \"tutd3-production\""
  type        = string
}

variable "readonly_users" {
  description = "Daftar nama IAM user yang masuk group readonly (policy ReadOnlyAccess)"
  type        = list(string)
  default     = []
}

variable "admin_users" {
  description = "Daftar nama IAM user yang masuk group admin (policy AdministratorAccess)"
  type        = list(string)
  default     = []
}

variable "console_login_pgp_key" {
  description = "PGP public key (base64) untuk mengenkripsi password console login user baru. Kosongkan (null) kalau user tidak butuh akses Console - password tidak akan dibuat."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
