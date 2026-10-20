module "bucket" {
  source = "../../../../modules/s3"

  bucket_name = var.bucket_name

  tags = {
    Environment = "staging"
    Purpose     = "app"
  }
}
