variable "prod_vm_sku" {
  default = {
    "Prod_env" = "Standard_D2ds_v4" ,
  }
}

variable "prod_db_sku" {
  type = map(string)
  default = {
    "Prod_env" = "GP_Standard_D2ads_v5" ,
    #"Dev_env" = "Standard_B1s"
  }
}

variable "count_number" {
  default = 2
}

variable "environment" {
  type        = string
  description = "Prod or Dev"
}

#variable "whitelisted_ip" {
#type    = string
#default = "104.40.239.157/32"
#}


variable "admin_user" {
  type      = string
  sensitive = true
}

variable "admin_db" {
  type      = string
  sensitive = true
}
variable "password_db" {
  type        = string
  description = "Your password must be at least 8 characters and at most 128 characters./nYour password must contain characters from three of the following categories – English uppercase letters, English lowercase letters, numbers (0-9), and non-alphanumeric characters (!, $, #, %, etc.)./nYour password cannot contain all or part of the login name. Part of a login name is defined as three or more consecutive alphanumeric characters."
  sensitive   = true
}