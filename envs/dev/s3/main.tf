module "app_bucket" {
  source = "../../../modules/s3"

  bucket_name = var.app_bucket_name

  tags = {
    Environment = "dev"
  }
}

module "test1_cempaka_bucket" {
  source = "../../../modules/s3"

  bucket_name = var.test1_cempaka_bucket_name

  tags = {
    Environment = "dev"
  }
}
