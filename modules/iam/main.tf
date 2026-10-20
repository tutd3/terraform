# Klasifikasi akses IAM lewat 2 group:
#   - readonly : lihat-lihat saja (AWS managed policy ReadOnlyAccess)
#   - admin    : akses penuh (AWS managed policy AdministratorAccess)
#
# User belum dibuat di sini secara default (var.readonly_users/admin_users
# kosong) - tinggal isi nama user lewat variable kapan saja, tidak perlu
# ubah modul ini.

resource "aws_iam_group" "readonly" {
  name = "${var.name_prefix}-readonly"
}

resource "aws_iam_group_policy_attachment" "readonly" {
  group      = aws_iam_group.readonly.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_group" "admin" {
  name = "${var.name_prefix}-admin"
}

resource "aws_iam_group_policy_attachment" "admin" {
  group      = aws_iam_group.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# SENGAJA 1 resource gabungan per user (bukan resource terpisah readonly/
# admin) - supaya pindah tier itu jadi UPDATE "groups" di resource yang SAMA,
# bukan destroy aws_iam_user di satu resource + create di resource lain.
# Kalau dipisah, pindah tier akan menghapus & membuat ulang USER IAM ASLI
# (hilang access key/password console-nya) - pernah kejadian pola yang sama
# di modul eks (access entry), di sini dampaknya lebih parah karena yang
# kehapus bukan cuma mapping akses, tapi user-nya sendiri.
locals {
  user_group_by_name = merge(
    { for name in var.readonly_users : name => "readonly" },
    { for name in var.admin_users : name => "admin" },
  )
}

resource "aws_iam_user" "this" {
  for_each = local.user_group_by_name
  name     = each.key
  tags     = var.tags
}

resource "aws_iam_user_group_membership" "this" {
  for_each = local.user_group_by_name
  user     = aws_iam_user.this[each.key].name
  groups   = [each.value == "admin" ? aws_iam_group.admin.name : aws_iam_group.readonly.name]
}

# --- Opsional: console login password untuk user baru ---
# Password di-generate acak oleh AWS/Terraform dan DIENKRIPSI di state pakai
# PGP public key yang kamu kasih (var.console_login_pgp_key) - supaya
# password tidak pernah tersimpan plaintext di state atau kelihatan di plan
# output. Output-nya cuma blob terenkripsi, didekripsi oleh pemilik private
# key (bukan oleh siapa pun yang menjalankan Terraform/CI).
resource "aws_iam_user_login_profile" "this" {
  for_each                = var.console_login_pgp_key != null ? local.user_group_by_name : {}
  user                    = aws_iam_user.this[each.key].name
  pgp_key                 = var.console_login_pgp_key
  password_reset_required = true
}
