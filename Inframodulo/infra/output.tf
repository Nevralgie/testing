output "Working_environment" {
  value = azurerm_resource_group.kube.tags
}

output "The_webserver_Public_ip_cltplane" {
  value       = azurerm_linux_virtual_machine.ctlplane.public_ip_address
  description = "The VM pubip"
}

output "pvtsshctl" {
  value     = tls_private_key.sshctl.private_key_pem
  sensitive = true
}

output "Lb_Pubip" {
  value = azurerm_public_ip.lbipkube.ip_address
}

output "NAT_ssh_ports" {
  value = azurerm_lb_nat_rule.natrules[*].frontend_port
}

output "Vms_admin_username" {
  value = azurerm_linux_virtual_machine.ctlplane.admin_username
  sensitive = true
}

output "Database_domain_name" {
  value = azurerm_private_dns_zone.private_dns.name
}

output "DB_admin_username" {
  value = azurerm_mysql_flexible_server.flxserv.administrator_login
  sensitive = true
}

output "DB_admin_password" {
  value = azurerm_mysql_flexible_server.flxserv.administrator_password
  sensitive = true
}


