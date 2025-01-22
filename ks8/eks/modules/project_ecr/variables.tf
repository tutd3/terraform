# reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository
variable repository_name {
  description = "ECR repository name"
  type        = string
}

variable image_tag_mutability {
  description = "The tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE. Defaults to MUTABLE"
  type        = string
  default     = "MUTABLE"
}

variable scan_on_push {
  description = "Indicates whether images are scanned after being pushed to the repository (true) or not scanned (false)."
  type        = bool
  default     = false
}
