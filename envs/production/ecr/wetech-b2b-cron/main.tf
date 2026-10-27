module "repository" {
  source = "../../../../modules/ecr"

  repository_name = var.repository_name

  tags = {
    Environment = "production"
    Service     = "b2b-cron"
  }
}
