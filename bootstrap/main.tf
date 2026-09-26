# Bootstrap ini HANYA dijalankan SEKALI, manual, oleh manusia (bukan CI).
# Tujuannya membuat prasyarat yang dibutuhkan sebelum CI/CD bisa mulai jalan:
#   1. S3 bucket untuk menyimpan Terraform state (envs/dev dst).
#   2. IAM OIDC provider supaya GitHub Actions bisa "pinjam" role AWS
#      tanpa perlu access key yang disimpan sebagai secret.
#   3. IAM role yang di-assume oleh GitHub Actions.
#
# State bootstrap ini disimpan LOKAL (backend default), karena saat pertama kali
# dijalankan, bucket state S3 belum ada. Simpan file terraform.tfstate hasil
# bootstrap ini baik-baik (atau pindahkan ke backend lain) supaya tidak hilang.

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- 1. S3 bucket untuk Terraform remote state ---
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  # Supaya bucket tidak sengaja terhapus lewat "terraform destroy"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- 2. IAM OIDC provider untuk GitHub Actions ---
# Thumbprint diambil otomatis dari sertifikat GitHub, tidak perlu hardcode manual.
data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]
}

# --- 3. IAM role yang di-assume oleh GitHub Actions workflow ---
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Dibatasi hanya untuk repo GitHub ini saja (branch/PR/environment apa pun
    # di dalam repo tersebut). Ganti pattern ini kalau mau dibatasi lebih ketat,
    # misalnya hanya branch main: "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions_terraform" {
  name                 = var.role_name
  assume_role_policy   = data.aws_iam_policy_document.github_actions_trust.json
  max_session_duration = 3600
}

# Sesuai permintaan awal: full admin access untuk mempercepat development.
# CATATAN: begitu semua modul (EC2/S3/EKS) sudah stabil, sangat disarankan
# mengganti ini dengan custom policy yang scoped ke service yang benar-benar
# dipakai, bukan AdministratorAccess permanen.
resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.github_actions_terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
