output "readonly_group_name" {
  value = aws_iam_group.readonly.name
}

output "admin_group_name" {
  value = aws_iam_group.admin.name
}

output "readonly_user_arns" {
  description = "ARN tiap user readonly - berguna untuk digunakan di tempat lain, mis. EKS access entry (AmazonEKSViewPolicy)"
  value       = { for name, u in aws_iam_user.this : name => u.arn if local.user_group_by_name[name] == "readonly" }
}

output "admin_user_arns" {
  description = "ARN tiap user admin - berguna untuk digunakan di tempat lain, mis. EKS access entry (AmazonEKSClusterAdminPolicy)"
  value       = { for name, u in aws_iam_user.this : name => u.arn if local.user_group_by_name[name] == "admin" }
}

# Password terenkripsi (PGP) - cuma ada kalau console_login_pgp_key diisi.
# Didekripsi oleh pemilik private key sendiri, bukan oleh siapa pun yang
# menjalankan Terraform/CI ini.
output "readonly_encrypted_passwords" {
  value     = { for name, p in aws_iam_user_login_profile.this : name => p.encrypted_password if local.user_group_by_name[name] == "readonly" }
  sensitive = true
}

output "admin_encrypted_passwords" {
  value     = { for name, p in aws_iam_user_login_profile.this : name => p.encrypted_password if local.user_group_by_name[name] == "admin" }
  sensitive = true
}
