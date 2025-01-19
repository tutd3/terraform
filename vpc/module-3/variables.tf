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

variable "enable_peering_connection" {
  description = "Enable peering connection routes in route table"
  type        = bool
  default     = false
}

variable "enable_transit_gateway" {
  description = "Enable transit gateway routes in route table"
  type        = bool
  default     = false
}

variable "enable_virtual_private_gateway" {
  description = "Enable virtual private gateway routes in route table"
  type        = bool
  default     = false
}

variable "vpc_peering_connection_ids" {
  description = "List of VPC peering connection IDs"
  type        = list(string)
  default     = []
}

variable "transit_gateway_ids" {
  description = "List of transit gateway IDs"
  type        = list(string)
  default     = []
}

variable "virtual_private_gateway_ids" {
  description = "List of virtual private gateway IDs"
  type        = list(string)
  default     = []
}

variable "peering_connection_cidr_blocks" {
  description = "List of CIDR blocks for the VPC peering connection"
  type        = list(string)
  default     = []
}

variable "transit_gateway_cidr_blocks" {
  description = "List of CIDR blocks for the transit gateway"
  type        = list(string)
  default     = []
}

variable "virtual_private_gateway_cidr_blocks" {
  description = "List of CIDR blocks for the virtual private gateway"
  type        = list(string)
  default     = []
}


