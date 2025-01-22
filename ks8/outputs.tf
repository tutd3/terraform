output project_ecr_url {
  description = "Map of created AWS ECR, outputting project name and repository url"
  value       = module.eks.project_ecr_url
}

output all_subnet_ids {
  description = "subnet ids from vpc created"
  value       = module.eks.all_subnet_ids
}

output public_subnet_ids {
  description = "public subnet ids from vpc created"
  value       = module.eks.public_subnet_ids
}

output private_subnet_ids {
  description = "private subnet ids from vpc created"
  value       = module.eks.private_subnet_ids
}

output nat_eip {
  description = "NAT public ip created"
  value       = module.eks.nat_eip
}

output cluster_endpoint {
  description = "The endpoint for your Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

output cluster_certificate_authority_data {
  description = "The base64 encoded certificate data required to communicate with your cluster. Add this to the certificate-authority-data section of the kubeconfig file for your cluster."
  value       = module.eks.cluster_certificate_authority_data
}

output cluster_autoscaler_iam_role_arn {
  description = "IAM role for cluster autoscaler reference: https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html"
  value       = module.eks.cluster_autoscaler_iam_role_arn
}

output worker_node_ids {
  description = "Map of created worker nodes in the cluster, return worker node name and id"
  value       = module.eks.worker_node_ids
}

output connect_to_cluster_command {
  description = "copy and paste this output to connect to EKS cluster created"
  value       = module.eks.connect_to_cluster_command
}

output "node_groups_autoscaling_name" {
  description = "list of objects containing information about autoscaling groups"
  value       = module.eks.node_groups_autoscaling_name
}
