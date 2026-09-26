variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  description = "Versi Kubernetes untuk EKS control plane"
  type        = string
  default     = "1.31"
}

variable "subnet_ids" {
  description = "Subnet (idealnya campuran publik & privat, minimal 2 AZ) untuk cluster & node group"
  type        = list(string)
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND atau SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "tags" {
  type    = map(string)
  default = {}
}
