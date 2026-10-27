resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = var.tags
}

# Lifecycle policy - auto-expire image lama (mis. cuma simpan N image
# terbaru per tag pattern) supaya storage ECR tidak numpuk terus. JSON
# mentah (bukan di-generate dari HCL) supaya fleksibel mengikuti format
# resmi AWS apa adanya - lihat
# https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html
resource "aws_ecr_lifecycle_policy" "this" {
  count      = var.lifecycle_policy_json != null ? 1 : 0
  repository = aws_ecr_repository.this.name
  policy     = var.lifecycle_policy_json
}

# Repository policy - IAM resource-based policy di repo ECR ini sendiri,
# dibutuhkan kalau ada PRINCIPAL DI AKUN AWS LAIN yang mau push/pull
# langsung ke repo ini (policy IAM biasa di akun lain itu TIDAK CUKUP untuk
# akses cross-account ke ECR - repo-nya sendiri juga harus "mengizinkan"
# lewat resource policy ini, sama seperti S3 bucket policy). JSON mentah
# supaya fleksibel buat principal/action apa pun yang dibutuhkan.
resource "aws_ecr_repository_policy" "this" {
  count      = var.repository_policy_json != null ? 1 : 0
  repository = aws_ecr_repository.this.name
  policy     = var.repository_policy_json
}
