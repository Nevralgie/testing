resource "azurerm_resource_group" "kube" {
  name     = "${var.environment}-TF-infra"
  location = "West Europe"
  tags = {
    Environment = "${var.environment}"
  }
}
# Create a virtual network within the resource group
resource "azurerm_virtual_network" "kubevnet" {
  name                = "kubevnet"
  resource_group_name = azurerm_resource_group.kube.name
  location            = azurerm_resource_group.kube.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "kubesub" {
  name                 = "ksubnet"
  resource_group_name  = azurerm_resource_group.kube.name
  virtual_network_name = azurerm_virtual_network.kubevnet.name
  address_prefixes     = ["10.0.0.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"

    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}



resource "azurerm_subnet" "kubesub2" {
  name                 = "ksubnet2"
  resource_group_name  = azurerm_resource_group.kube.name
  virtual_network_name = azurerm_virtual_network.kubevnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

locals {
  security_rules = {
    "Http" = {
      priority               = 100
      source_port_range      = "*"
      destination_port_range = "80"
    }
    "Https" = {
      priority               = 200
      source_port_range      = "*"
      destination_port_range = "443"
    }
    "ssh" = {
      priority               = 101
      source_port_range      = "*"
      destination_port_range = "22"
    }

  }
}

resource "azurerm_network_security_group" "kube" {
  name                = "kubensg"
  location            = azurerm_resource_group.kube.location
  resource_group_name = azurerm_resource_group.kube.name

  dynamic "security_rule" {
    for_each = local.security_rules

    iterator = port
    content {
      name                       = port.key
      priority                   = port.value.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = port.value.source_port_range
      destination_port_range     = port.value.destination_port_range
      source_address_prefix      = "*" #var.whitelisted_ip
      destination_address_prefix = "*"

    }
  }
  security_rule {
    name                       = "all"
    priority                   = 400
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }
}

resource "azurerm_public_ip" "masterip" {
  name                = "ctlpubip"
  location            = azurerm_resource_group.kube.location
  resource_group_name = azurerm_resource_group.kube.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "kbnic" {
  name                = "knic1"
  location            = azurerm_resource_group.kube.location
  resource_group_name = azurerm_resource_group.kube.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.kubesub2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.masterip.id
  }
}

resource "tls_private_key" "sshctl" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "ctlplane" {
  name                = "${var.environment}-master"
  resource_group_name = azurerm_resource_group.kube.name
  location            = azurerm_resource_group.kube.location
  size                = var.environment == "Prod" ? var.vm_sku["Prod_env"] : var.vm_sku["Dev_env"]
  admin_username      = var.admin_user
  network_interface_ids = [
    azurerm_network_interface.kbnic.id,
  ]


  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.sshctl.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  tags = {
    role = "master.kubernetes.lab"
  }
}


resource "azurerm_public_ip" "workersip" {
  count               = var.environment == "Prod" ? 0 : var.count_number
  name                = "ctlpubip${count.index}"
  location            = azurerm_resource_group.kube.location
  resource_group_name = azurerm_resource_group.kube.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_network_interface" "kwk" {
  count               = var.count_number
  name                = "acctni${count.index}"
  location            = azurerm_resource_group.kube.location
  resource_group_name = azurerm_resource_group.kube.name

  ip_configuration {
    name                          = "ipConfiguration${count.index}"
    subnet_id                     = azurerm_subnet.kubesub2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.environment == "Prod" ? null : azurerm_public_ip.workersip[count.index].id
  }
}


resource "azurerm_managed_disk" "test" {
  count                = var.count_number
  name                 = "datadisk_existing_${count.index}"
  location             = azurerm_resource_group.kube.location
  resource_group_name  = azurerm_resource_group.kube.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "20"
}


resource "azurerm_linux_virtual_machine" "workers" {
  count                 = var.count_number
  name                  = "${var.environment}-worker-${count.index}"
  location              = azurerm_resource_group.kube.location
  resource_group_name   = azurerm_resource_group.kube.name
  admin_username        = var.admin_user
  network_interface_ids = [azurerm_network_interface.kwk[count.index].id]
  size                  = var.environment == "Prod" ? var.vm_sku["Prod_env"] : var.vm_sku["Dev_env"]
  custom_data           = base64encode(file("${path.module}/init-script.bash"))


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.sshctl.public_key_openssh
  }

  tags = {
    role = "Workers"
  }
}


resource "azurerm_network_interface_security_group_association" "linkctlnic" {
  network_interface_id      = azurerm_network_interface.kbnic.id
  network_security_group_id = azurerm_network_security_group.kube.id
}


resource "azurerm_network_interface_security_group_association" "linkwks" {
  count                     = var.count_number
  network_interface_id      = azurerm_network_interface.kwk[count.index].id
  network_security_group_id = azurerm_network_security_group.kube.id
}