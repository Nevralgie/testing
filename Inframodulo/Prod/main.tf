module "infra" {
  source = "../infra"
  vm_sku = var.prod_vm_sku
  db_sku = var.prod_db_sku
  admin_db = var.admin_db
  password_db = var.password_db
  environment = var.environment
  admin_user = var.admin_user
}
