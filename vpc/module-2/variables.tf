# variables.tf

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

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "assign_ipv6" {
  description = "Whether to assign IPv6 to subnets"
  type        = bool
  default     = false
}

#variable "additional_public_cidr" {
#  description = "Optional additional CIDR block for the public subnet"
#  type        = string
#  default     = ""
#}

#variable "additional_private_cidr" {
#  description = "Optional additional CIDR block for the private subnet"
#  type        = string
#  default     = ""
#}

