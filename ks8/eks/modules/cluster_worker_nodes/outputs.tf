output ids {
  description = "Map of worker node ids"
  value       = {
    for w in keys(var.worker_nodes) :
    w => aws_eks_node_group.main[w].id
  }
}

output autoscaling_group_name {
  value       = local.cluster_output_worker_nodes_autoscalling_group_name
}

output map_node_groups_tags {
  value = local.map_node_groups_tags
}
output aws_iam_instance_profile {
  value       = aws_iam_instance_profile.worker_node.role
  description = "description"
}
