# Daftar user diambil dari NAMA FILE di folder users/readonly/ dan
# users/admin/ (lihat README.md di masing-masing folder) - bukan dari
# variable lagi. Pindahkan file antar folder untuk pindah tier (aman, lihat
# komentar di modules/iam/main.tf), hapus file untuk hapus akses total.
# README.md di tiap folder cuma dokumentasi, bukan nama user - dikecualikan
# di bawah, begitu juga file titik (mis. .gitkeep).
locals {
  readonly_users_dir = sort([
    for f in fileset("${path.module}/users/readonly", "*") :
    f if f != "README.md" && !startswith(f, ".")
  ])
  admin_users_dir = sort([
    for f in fileset("${path.module}/users/admin", "*") :
    f if f != "README.md" && !startswith(f, ".")
  ])
}

module "iam" {
  source = "../../../modules/iam"

  name_prefix           = var.name_prefix
  readonly_users        = local.readonly_users_dir
  admin_users           = local.admin_users_dir
  console_login_pgp_key = var.console_login_pgp_key

  tags = {
    Environment = "production"
  }
}
