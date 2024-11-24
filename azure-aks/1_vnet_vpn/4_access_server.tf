# Name: access_server.tf
# Owner: Saurav Mitra
# Description: This terraform config will create 1 Virtual Machine as OpenVPN Access Server

# Network Security Group
resource "azurerm_network_security_group" "vpn_security_group" {
  name                = "${var.prefix}-vpn-nsg"
  location            = var.rg_location
  resource_group_name = var.rg_name

  security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "TCP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "TCP1"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "943"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "TCP2"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "945"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "UDP"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "1194"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name  = "${var.prefix}-vpn-nsg"
    Owner = var.owner
  }
}


# Public IP for VM
resource "azurerm_public_ip" "vpn_public_ip" {
  name                = "${var.prefix}-vpn-public-ip"
  location            = var.rg_location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Name  = "${var.prefix}-vpn-public-ip"
    Owner = var.owner
  }
}

# Network Interface Card
resource "azurerm_network_interface" "vpn_nic" {
  name                = "${var.prefix}-vpn-nic"
  location            = var.rg_location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public_subnet[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vpn_public_ip.id
  }

  tags = {
    Name  = "${var.prefix}-vpn-nic"
    Owner = var.owner
  }
}

# NIC & NSG Association
resource "azurerm_network_interface_security_group_association" "vpn_nic_sg_assoc" {
  network_interface_id      = azurerm_network_interface.vpn_nic.id
  network_security_group_id = azurerm_network_security_group.vpn_security_group.id
}

# User Data Init
data "template_file" "init" {
  template = file("${path.module}/3_config_server.sh")

  vars = {
    VPN_ADMIN_USER     = var.vpn_admin_user
    VPN_ADMIN_PASSWORD = var.vpn_admin_password
    VNET_NAME_SERVER   = cidrhost(var.vnet_cidr_block, 1)
    VNET_CIDR_BLOCK    = var.vnet_cidr_block
    PUBLIC_IP          = azurerm_public_ip.vpn_public_ip.ip_address
  }
}

# VM
resource "azurerm_virtual_machine" "vpn_vm" {
  name                             = "${var.prefix}-vpn-vm"
  location                         = var.rg_location
  resource_group_name              = var.rg_name
  network_interface_ids            = [azurerm_network_interface.vpn_nic.id]
  vm_size                          = var.vm_size
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}-vpn-vm-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      key_data = var.ssh_public_key
      path     = "/home/${var.ssh_user}/.ssh/authorized_keys"
    }
  }

  os_profile {
    computer_name  = "${var.prefix}-vpn-vm"
    admin_username = var.ssh_user
    custom_data    = data.template_file.init.rendered
  }

  tags = {
    Name  = "${var.prefix}-vpn-vm"
    Owner = var.owner
  }
}
