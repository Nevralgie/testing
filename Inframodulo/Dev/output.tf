output "Working_environment" {
  value = module.infra.Working_environment
}

output "The_webserver_Public_ip_cltplane" {
  value       = module.infra.The_webserver_Public_ip_cltplane
  description = "The VM pubip"
}

output "pvtsshctl" {
  value     =  module.infra.pvtsshctl
  sensitive = true
}

output "Lb_Pubip" {
  value =  module.infra.Lb_Pubip
}

output "NAT_ssh_ports" {
  value =  module.infra.NAT_ssh_ports
}

output "Vms_admin_username" {
  value =  module.infra.Vms_admin_username
  sensitive = true
}

output "Database_domain_name" {
  value =  module.infra.Database_domain_name
}
output "DB_admin_username" {
  value =  module.infra.DB_admin_username
  sensitive = true
}

output "DB_admin_password" {
  value =  module.infra.DB_admin_password
  sensitive = true
}


