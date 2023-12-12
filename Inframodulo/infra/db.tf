resource "azurerm_mysql_flexible_server" "flxserv" {
  name                   = "flexservtom"
  resource_group_name    = azurerm_resource_group.kube.name
  location               = azurerm_resource_group.kube.location
  administrator_login    = var.admin_db
  administrator_password = var.password_db
  sku_name               = var.environment == "Prod" ? var.db_sku["Prod_env"] : var.db_sku["Dev_env"]
  zone                   = 1
  delegated_subnet_id    = azurerm_subnet.kubesub.id
  private_dns_zone_id    = azurerm_private_dns_zone.private_dns.id
}

resource "azurerm_mysql_flexible_database" "flexdb" {
  depends_on          = [azurerm_mysql_flexible_server.flxserv, azurerm_private_dns_zone_virtual_network_link.networklink]
  name                = "FlexDBTom"
  resource_group_name = azurerm_resource_group.kube.name
  server_name         = azurerm_mysql_flexible_server.flxserv.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

resource "azurerm_private_dns_zone" "private_dns" {
  name                = "tredevops.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.kube.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "networklink" {
  name                  = "Dns-Link"
  resource_group_name   = azurerm_resource_group.kube.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns.name
  virtual_network_id    = azurerm_virtual_network.kubevnet.id
}