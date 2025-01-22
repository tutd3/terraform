variable aws_account_id {
  description = "AWS Account ID"
  type        = string
}

variable cluster_name {
  description = "EKS cluster name"
  type        = string
}

variable k8s_version {
  description = "kubernetes version"
  type        = string
}

variable service_ipv4_cidr {
  description = "The CIDR block to assign Kubernetes service IP addresses from. EKS Default assigns either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks."
  type        = string
}

variable vpc_id {
  description = "VPC id"
  type        = string
}

variable subnet_ids {
  description = "VPC subnet ids"
  type        = list
}

variable public_access_cidrs {
  description = "List of CIDR blocks. Indicates which CIDR blocks can access the Amazon EKS public API server endpoint when enabled. EKS defaults this to a list with 0.0.0.0/0"
  type        = list
}

variable endpoint_private_access {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
}

variable endpoint_public_access {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
}

variable cluster_tags {
  description = "EKS tags"
  type        = map
}
