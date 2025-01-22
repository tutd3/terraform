variable cluster_name {
  description = "EKS cluster name"
  type        = string
}

variable k8s_version {
  description = "kubernetes version"
  type        = string
}

variable public_subnet_ids {
  description = "VPC public subnet ids"
  type        = list
}

variable private_subnet_ids {
  description = "VPC private subnet ids"
  type        = list
}

variable public_subnet_ids2 {
  description = "VPC public subnet ids"
  type        = list
}

variable private_subnet_ids2 {
  description = "VPC private subnet ids"
  type        = list
}

variable private_subnet_ids3 {
  description = "VPC private subnet ids"
  type        = list
}

variable public_subnet_ids3 {
  description = "VPC public subnet ids"
  type        = list
}

variable worker_nodes {
  # description = "Map of worker nodes manage by cluster"
  # type        = map
}

variable cluster_tags {
  description = "EKS tags"
  type        = map
}

variable "cluster_addons" {
  description = "EKS addons"
  default     = {}
}

variable "cluster_addons_timeouts" {
  type        = map(string)
  default     = {}
}

variable use_custom_launch_template {
  description = "For using launch template on node worker"
  type        = bool
}
variable launch_template_variable {
  description = "launch template variable"
  type        = map
}