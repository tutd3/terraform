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
