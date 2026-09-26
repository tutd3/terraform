output "vpc_id" {
  value = module.vpc.vpc_id
}

output "app_bucket_name" {
  value = module.app_bucket.bucket_name
}

output "ec2_public_ip" {
  value = var.enable_ec2 ? module.example_ec2[0].public_ip : null
}

output "eks_cluster_name" {
  value = var.enable_eks ? module.eks[0].cluster_name : null
}

output "eks_cluster_endpoint" {
  value = var.enable_eks ? module.eks[0].cluster_endpoint : null
}
