module "repository" {
  source = "../../../../modules/ecr"

  repository_name = var.repository_name

  # Simpan maksimal 10 image terbaru per pola tag - sisanya di-expire
  # otomatis supaya storage ECR tidak numpuk terus.
  lifecycle_policy_json = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep 10 staging images"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["*-staging"]
          countType      = "imageCountMoreThan"
          countNumber    = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep 10 production images"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["*-production"]
          countType      = "imageCountMoreThan"
          countNumber    = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = {
    Environment = "production"
    Service     = "b2b-cron"
  }
}
