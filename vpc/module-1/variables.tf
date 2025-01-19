variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "project_tag" {
  description = "The project tag"
  type        = string
}

variable "environment_tag" {
  description = "The environment tag"
  type        = string
}

variable "assign_ipv6" {
  description = "Whether to assign IPv6 address to subnets"
  type        = bool
  default     = false
}

