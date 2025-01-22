output "ecr_url" {
  description = "Elastic Container Registry created url"
  value       = aws_ecr_repository.main.repository_url
}
