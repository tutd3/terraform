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

variable "node_disk_size_gb" {
  description = "Ukuran EBS root volume tiap worker node (GB). Default AWS kalau tidak diset adalah 20GB - sering kurang untuk image container yang banyak/besar."
  type        = number
  default     = 20
}

variable "small_instance_mode" {
  description = "Set true kalau node pakai instance kecil (mis. t3.micro/small) yang terbatas jumlah pod & memorinya - menurunkan replica addon ke 1 dan mengaktifkan VPC CNI prefix delegation. Set false untuk instance normal (t3.medium ke atas) supaya addon tetap HA (2 replica)."
  type        = bool
  default     = false
}

variable "admin_principal_arns" {
  description = "Daftar IAM principal ARN (user/role/root) yang diberi akses admin penuh ke Kubernetes API cluster ini lewat EKS Access Entry. Role yang membuat cluster (CI) otomatis sudah dapat akses - ini untuk principal LAIN, mis. root user akun AWS supaya bisa lihat resource Kubernetes di AWS Console."
  type        = list(string)
  default     = []
}

variable "viewer_principal_arns" {
  description = "Daftar IAM principal ARN yang diberi akses VIEW-ONLY ke Kubernetes API cluster ini lewat EKS Access Entry (AmazonEKSViewPolicy) - cocok untuk IAM user di group readonly. Principal yang sudah ada di admin_principal_arns otomatis di-skip di sini (tidak bisa dobel access entry)."
  type        = list(string)
  default     = []
}

variable "vpc_cidr" {
  description = "CIDR block VPC tempat cluster ini berada - dipakai untuk rule security group yang mengizinkan traffic antar-resource di dalam VPC yang sama."
  type        = string
}

variable "node_sg_allow_web_public" {
  description = "Set true untuk buka port 80/443 di security group node dari 0.0.0.0/0 - dibutuhkan kalau ada NLB/ingress controller yang terusin traffic publik langsung ke node (mis. instance-mode target group)."
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Aktifkan kapasitas enforce Kubernetes NetworkPolicy lewat vpc-cni (tidak perlu Calico/Cilium tambahan). Tidak ada efek sampai ada objek NetworkPolicy yang dibuat lewat kubectl."
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
