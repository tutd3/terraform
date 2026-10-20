module "bucket" {
  source = "../../../../modules/s3"

  bucket_name = var.bucket_name

  tags = {
    Environment = "dev"
    Purpose     = "test1-cempaka"
  }
}
