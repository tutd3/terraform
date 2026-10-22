module "iam" {
  source = "../../../modules/iam"

  name_prefix           = var.name_prefix
  readonly_users        = var.readonly_users
  admin_users           = var.admin_users
  console_login_pgp_key = var.console_login_pgp_key

  tags = {
    Environment = "production"
  }
}

# Role yang bisa di-assume oleh IAM user/role MANA PUN di akun ini (akun
# sendiri jadi trusted principal), supaya bisa lihat/kelola resource
# Kubernetes di cluster EKS production lewat AWS Console/CLI.
#
# PENTING: ini terpisah total dari "AmazonEKSClusterPolicy" yang dipakai role
# control plane EKS (lihat modules/eks) - policy itu isinya permission
# EC2/ELB untuk cluster MENGELOLA infra-nya sendiri, SAMA SEKALI tidak ada
# permission eks:* dan tidak ada hubungannya dengan manusia yang mau lihat
# Console. Role di bawah ini justru yang menjawab kebutuhan itu.
data "aws_iam_policy_document" "eks_cluster_role_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::094983223261:root"]
    }
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name               = "EKSClusterRole"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_role_assume.json

  tags = {
    Environment = "production"
  }
}

# Izin IAM minimum supaya Console/CLI bisa manggil EKS API DAN proxy ke
# Kubernetes API cluster (eks:AccessKubernetesApi). Tanpa ini, access entry
# EKS (lihat modules/eks - admin_principal_arns) tidak akan berguna sama
# sekali meskipun RBAC-nya sudah benar, karena Console/CLI bahkan tidak bisa
# "nyambung" ke cluster-nya sejak awal.
data "aws_iam_policy_document" "eks_cluster_role_access" {
  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:ListNodegroups",
      "eks:DescribeNodegroup",
      "eks:AccessKubernetesApi",
      "ec2:DescribeInstances",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "eks_cluster_role_access" {
  name   = "eks-cluster-api-access"
  role   = aws_iam_role.eks_cluster_role.id
  policy = data.aws_iam_policy_document.eks_cluster_role_access.json
}
