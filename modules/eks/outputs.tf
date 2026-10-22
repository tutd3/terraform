output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.cluster.arn
}

output "node_role_arn" {
  value = aws_iam_role.node.arn
}

output "cluster_role_name" {
  value = aws_iam_role.cluster.name
}

output "lb_controller_role_arn" {
  description = "ARN role IRSA untuk AWS Load Balancer Controller - pakai ini buat annotate service account kube-system/aws-load-balancer-controller saat install controller-nya (lihat modules/eks/main.tf)."
  value       = aws_iam_role.lb_controller.arn
}

output "karpenter_controller_role_arn" {
  description = "ARN role IRSA controller Karpenter - pakai ini buat annotate service account kube-system/karpenter saat install Karpenter (Helm). Kosong (null) kalau enable_karpenter = false."
  value       = var.enable_karpenter ? aws_iam_role.karpenter_controller[0].arn : null
}

output "karpenter_node_role_name" {
  description = "Nama role untuk node yang nanti dibuat Karpenter - isi ini di EC2NodeClass.spec.role. Kosong (null) kalau enable_karpenter = false."
  value       = var.enable_karpenter ? aws_iam_role.karpenter_node[0].name : null
}

output "karpenter_interruption_queue_name" {
  description = "Nama SQS interruption queue - isi ini di Helm value settings.interruptionQueue saat install Karpenter. Kosong (null) kalau enable_karpenter = false."
  value       = var.enable_karpenter ? aws_sqs_queue.karpenter_interruption[0].name : null
}
