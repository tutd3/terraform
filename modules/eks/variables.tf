variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  description = "Versi Kubernetes untuk EKS control plane"
  type        = string
  default     = "1.36"
}

variable "subnet_ids" {
  description = "Subnet untuk CLUSTER (control plane) - WAJIB minimal 2 AZ, ini syarat AWS untuk EKS, tidak bisa 1 AZ."
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "Subnet khusus untuk WORKER NODE - boleh beda dari subnet_ids cluster (mis. cuma 1-2 AZ untuk hemat biaya, sementara cluster control plane tetap multi-AZ). Kosongkan ([], default) untuk pakai subnet_ids yang sama seperti cluster (semua AZ)."
  type        = list(string)
  default     = []
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

variable "enable_karpenter" {
  description = "Set true untuk menyiapkan IAM role, SQS interruption queue, EventBridge rule, dan tag discovery subnet/security group yang dibutuhkan Karpenter (node provisioning dinamis - Karpenter yang bikin EC2 instance sesuai kebutuhan pod, bukan node group static). Karpenter sendiri (controller pod + manifest NodePool/EC2NodeClass di Kubernetes) TIDAK ter-install di sini - itu langkah terpisah (Helm), lihat output karpenter_* untuk nilai yang dibutuhkan saat install."
  type        = bool
  default     = false
}

variable "node_group_system_taint" {
  description = "Set true untuk kasih taint nodegroup/system=false:NoSchedule ke node group default - menjadikan node group ini KHUSUS buat addon sistem (CoreDNS, EBS CSI controller - sudah dikasih toleration yang cocok di modul ini). kube-proxy & vpc-cni tidak perlu toleration tambahan (sudah toleransi semua taint by default dari AWS). PENTING: kalau ini node group SATU-SATUNYA di cluster, pod aplikasi biasa (tanpa toleration yang sama) tidak akan bisa di-schedule sama sekali sampai ada node group lain yang tidak di-taint."
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

variable "lb_controller_namespace_patterns" {
  description = "Daftar pattern namespace (boleh wildcard \"*\", mis. \"foundation*\") yang diizinkan menjalankan AWS Load Balancer Controller dan assume role IRSA-nya. Nama service account WAJIB persis \"aws-load-balancer-controller\" (ikut nama release Helm). HATI-HATI dengan wildcard longgar - siapa pun yang bisa bikin ServiceAccount dengan nama itu di namespace yang cocok pattern otomatis dapat akses penuh LB Controller (bikin/hapus ALB, ubah security group, dll)."
  type        = list(string)
  default     = ["kube-system"]
}

variable "enable_network_policy" {
  description = "Aktifkan kapasitas enforce Kubernetes NetworkPolicy lewat vpc-cni (tidak perlu Calico/Cilium tambahan). Tidak ada efek sampai ada objek NetworkPolicy yang dibuat lewat kubectl."
  type        = bool
  default     = false
}

variable "enable_public_access" {
  description = "Set false (default, lebih aman) supaya API server Kubernetes CUMA bisa diakses dari dalam VPC (lewat VPN/bastion yang masuk ke VPC ini) - endpoint publik dimatikan total, tidak sekadar dibatasi IP. CI/CD tetap jalan normal walau false, karena Terraform mengelola cluster lewat AWS EKS control plane API (eks:*), bukan lewat API server Kubernetes-nya langsung. Set true kalau mau akses dari internet tanpa VPN (TIDAK disarankan untuk production)."
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
