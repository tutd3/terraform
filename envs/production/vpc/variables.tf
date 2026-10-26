variable "aws_region" {
  type    = string
  default = "ap-southeast-3"
}

variable "name_prefix" {
  type    = string
  default = "wetech-production"
}

variable "tag_for_eks" {
  description = "Set true supaya subnet ditag untuk auto-discovery EKS (stack eks/ pakai VPC ini)"
  type        = bool
  default     = true
}

# Override dari default module (10.0.0.0/16 dkk) - dipakai kalau butuh range
# IP lain, mis. supaya tidak tumpang tindih dengan VPC lain yang nanti mau
# di-peering/VPN. public_subnet_cidrs & private_subnet_cidrs WAJIB ikut
# diganti konsisten dengan vpc_cidr - keduanya harus berada DI DALAM range
# vpc_cidr, kalau tidak "terraform apply" akan gagal (AWS mewajibkan subnet
# CIDR adalah bagian dari VPC CIDR-nya).
variable "vpc_cidr" {
  type    = string
  default = "10.103.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.103.0.0/24", "10.103.1.0/24", "10.103.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.103.10.0/24", "10.103.11.0/24", "10.103.12.0/24"]
}

# Kosong dulu (belum ada VPN/peering/Transit Gateway) - isi lewat PR kapan
# saja. Lihat deskripsi variable yang sama di modules/vpc/variables.tf untuk
# format tiap elemen (cidr_block + tepat satu target).
variable "additional_public_routes" {
  type = list(object({
    cidr_block                = string
    gateway_id                = optional(string)
    nat_gateway_id            = optional(string)
    transit_gateway_id        = optional(string)
    vpc_peering_connection_id = optional(string)
    network_interface_id      = optional(string)
  }))
  default = []
}

variable "additional_private_routes" {
  type = list(object({
    cidr_block                = string
    gateway_id                = optional(string)
    nat_gateway_id            = optional(string)
    transit_gateway_id        = optional(string)
    vpc_peering_connection_id = optional(string)
    network_interface_id      = optional(string)
  }))
  # CONTOH SAJA - PR ini tidak dimaksudkan untuk di-merge. pcx-02e2bda5882a1f797
  # ada di akun AWS LAIN (bukan akun yang dikelola repo ini), cuma
  # menunjukkan DI MANA isi route peering ditaruh dan formatnya seperti apa
  # (cidr_block + vpc_peering_connection_id, field target lain dikosongkan).
  default = [
    {
      cidr_block                = "172.10.0.0/16"
      vpc_peering_connection_id = "pcx-02e2bda5882a1f797"
    }
  ]
}
