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

variable "tags" {
  type    = map(string)
  default = {}
}
