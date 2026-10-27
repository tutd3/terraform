variable "repository_name" {
  description = "Nama ECR repository."
  type        = string
}

variable "image_tag_mutability" {
  description = "IMMUTABLE (default, disarankan) = tag yang sudah dipush tidak bisa ditimpa image lain (mis. push ulang tag \"latest\" dengan isi beda akan ditolak) - mencegah image production berubah diam-diam di bawah tag yang sama. MUTABLE kalau memang butuh bisa timpa tag yang sama."
  type        = string
  default     = "IMMUTABLE"
}

variable "scan_on_push" {
  description = "Scan kerentanan (vulnerability) otomatis tiap ada image baru di-push."
  type        = bool
  default     = true
}

variable "lifecycle_policy_json" {
  description = "JSON lifecycle policy (format resmi AWS, mis. hasil copy dari AWS Console atau tulis manual sesuai dokumentasi ECR) - buat auto-expire image lama. Kosongkan (null) untuk tidak ada lifecycle policy (image disimpan selamanya)."
  type        = string
  default     = null
}

variable "repository_policy_json" {
  description = "JSON resource-based policy repository (IAM policy document) - dibutuhkan HANYA kalau ada IAM principal di AKUN AWS LAIN yang perlu push/pull langsung ke repo ini. Kosongkan (null) kalau cuma dipakai dari akun ini sendiri (cukup diatur lewat IAM policy biasa di sisi principal-nya, tidak perlu resource policy ini)."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
