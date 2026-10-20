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

# --- User readonly ---
resource "aws_iam_user" "readonly" {
  for_each = toset(var.readonly_users)
  name     = each.value
  tags     = var.tags
}

resource "aws_iam_user_group_membership" "readonly" {
  for_each = toset(var.readonly_users)
  user     = aws_iam_user.readonly[each.value].name
  groups   = [aws_iam_group.readonly.name]
}

# --- User admin ---
resource "aws_iam_user" "admin" {
  for_each = toset(var.admin_users)
  name     = each.value
  tags     = var.tags
}

resource "aws_iam_user_group_membership" "admin" {
  for_each = toset(var.admin_users)
  user     = aws_iam_user.admin[each.value].name
  groups   = [aws_iam_group.admin.name]
}

# --- Opsional: console login password untuk user baru ---
# Password di-generate acak oleh AWS/Terraform dan DIENKRIPSI di state pakai
# PGP public key yang kamu kasih (var.console_login_pgp_key) - supaya
# password tidak pernah tersimpan plaintext di state atau kelihatan di plan
# output. Output-nya cuma blob terenkripsi, didekripsi oleh pemilik private
# key (bukan oleh siapa pun yang menjalankan Terraform/CI).
resource "aws_iam_user_login_profile" "readonly" {
  for_each                = var.console_login_pgp_key != null ? toset(var.readonly_users) : []
  user                    = aws_iam_user.readonly[each.value].name
  pgp_key                 = var.console_login_pgp_key
  password_reset_required = true
}

resource "aws_iam_user_login_profile" "admin" {
  for_each                = var.console_login_pgp_key != null ? toset(var.admin_users) : []
  user                    = aws_iam_user.admin[each.value].name
  pgp_key                 = var.console_login_pgp_key
  password_reset_required = true
}
