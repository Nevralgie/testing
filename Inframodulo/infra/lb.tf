resource "azurerm_public_ip" "lbipkube" {
  name                = "pubIPLB"
  location            = azurerm_resource_group.kube.location
  resource_group_name = azurerm_resource_group.kube.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "klb" {
  name                = "lbtom"
  location            = azurerm_resource_group.kube.location
  resource_group_name = azurerm_resource_group.kube.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "publicIPAddress"
    public_ip_address_id = azurerm_public_ip.lbipkube.id
  }
}

resource "azurerm_lb_backend_address_pool" "kpool" {
  loadbalancer_id = azurerm_lb.klb.id
  name            = "BackEndAddressPool"
}


resource "azurerm_network_interface_backend_address_pool_association" "bpassoc" {
  count                   = var.count_number
  network_interface_id    = azurerm_network_interface.kwk[count.index].id
  ip_configuration_name   = "ipConfiguration${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.kpool.id

}

resource "azurerm_lb_rule" "HttpLbrule" {
  loadbalancer_id                = azurerm_lb.klb.id
  name                           = "LBRulehttp"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "publicIPAddress"
  probe_id                       = azurerm_lb_probe.probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.kpool.id]
}

resource "azurerm_lb_probe" "probe" {
  loadbalancer_id = azurerm_lb.klb.id
  name            = "httprobe"
  port            = 80
}

resource "azurerm_lb_nat_rule" "natrules" {
  count                          = var.environment == "Prod" ? var.count_number : 0
  resource_group_name            = azurerm_resource_group.kube.name
  loadbalancer_id                = azurerm_lb.klb.id
  name                           = "SSHAccess${count.index}"
  protocol                       = "Tcp"
  frontend_port                  = 201 + count.index
  backend_port                   = 22
  frontend_ip_configuration_name = "publicIPAddress"
}

resource "azurerm_network_interface_nat_rule_association" "natrules_association" {
  count                 = var.environment == "Prod" ? var.count_number : 0
  network_interface_id  = azurerm_network_interface.kwk[count.index].id
  ip_configuration_name = "ipConfiguration${count.index}"
  nat_rule_id           = azurerm_lb_nat_rule.natrules[count.index].id
}
