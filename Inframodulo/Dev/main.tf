module "infra" {
  source = "./infra"
  vm_sku = var.dev_vm_sku
  db_sku = var.dev_db_sku
  admin_db = var.admin_db
  password_db = var.password_db
  environment = var.environment
  admin_user = var.admin_user
}
