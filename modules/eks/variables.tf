variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  description = "Versi Kubernetes untuk EKS control plane"
  type        = string
  default     = "1.36"
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

variable "small_instance_mode" {
  description = "Set true kalau node pakai instance kecil (mis. t3.micro/small) yang terbatas jumlah pod & memorinya - menurunkan replica addon ke 1 dan mengaktifkan VPC CNI prefix delegation. Set false untuk instance normal (t3.medium ke atas) supaya addon tetap HA (2 replica)."
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
