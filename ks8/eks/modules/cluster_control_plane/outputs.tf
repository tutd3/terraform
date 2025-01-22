output endpoint {
  value = aws_eks_cluster.main.endpoint
}

output id {
  value = aws_eks_cluster.main.id
}

output certificate_authority_data {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output autoscaler_iam_role_arn {
  value = aws_iam_role.autoscaler.arn
}