variable "bucket_name" {
  description = "Nama bucket S3 (harus unik secara global di seluruh AWS)"
  type        = string
}

variable "enable_versioning" {
  description = "Aktifkan versioning supaya object lama tidak hilang saat ditimpa/dihapus"
  type        = bool
  default     = true
}

variable "lifecycle_expiration_days" {
  description = "Kalau diisi, object otomatis dihapus setelah sekian hari. Kosongkan (null) untuk simpan selamanya."
  type        = number
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
