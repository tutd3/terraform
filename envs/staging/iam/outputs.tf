output "readonly_group_name" {
  value = module.iam.readonly_group_name
}

output "admin_group_name" {
  value = module.iam.admin_group_name
}

output "readonly_user_arns" {
  value = module.iam.readonly_user_arns
}

output "admin_user_arns" {
  value = module.iam.admin_user_arns
}
