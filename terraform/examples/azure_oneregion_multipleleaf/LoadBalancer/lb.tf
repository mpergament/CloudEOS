provider "azurerm" {
  skip_provider_registration = true
  features {}
}

data "azurerm_resource_group" "rg" {
  name       = var.static_rg_vnet_info["edge1"]["rg"]
}

data "azurerm_virtual_network" "vnet" {
  name                = var.static_rg_vnet_info["edge1"]["vnet"]
  resource_group_name = var.static_rg_vnet_info["edge1"]["rg"]
}

data "azurerm_subnet" "subnet" {
  name                 = var.subnet_info["edge1subnet"]["subnet_names"][count.index]
  virtual_network_name = var.static_rg_vnet_info["edge1"]["vnet"]
  resource_group_name  = var.static_rg_vnet_info["edge1"]["rg"]
  count                = length(var.subnet_info["edge1subnet"]["subnet_names"])
}

data "azurerm_network_interface" "firstif" {
  name                = "edge1cloudeos1Intf0"
  resource_group_name = var.static_rg_vnet_info["edge1"]["rg"]
}

resource "azurerm_lb" "cloudedgelb" {
  name                = "AMADEUS-TEST"
  location            = data.azurerm_virtual_network.vnet.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name      = "Amadeus-IP1"
    subnet_id = data.azurerm_subnet.subnet[0].id
  }
  frontend_ip_configuration {
    name      = "Amadeus-IP2"
    subnet_id = data.azurerm_subnet.subnet[0].id
  }
}

resource "azurerm_lb_rule" "rule1" {
  resource_group_name            = var.static_rg_vnet_info["edge1"]["rg"]
  loadbalancer_id                = azurerm_lb.cloudedgelb.id
  name                           = "rule1"
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "Amadeus-IP1"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.pool1[0].id
  probe_id                       = azurerm_lb_probe.probe[0].id
  load_distribution              = "Default"
}

resource "azurerm_lb_probe" "probe" {
  resource_group_name = var.static_rg_vnet_info["edge1"]["rg"]
  loadbalancer_id     = azurerm_lb.cloudedgelb.id
  name                = "ssh-probe"
  port                = 22
  protocol            = "Tcp"
}

resource "azurerm_network_interface_backend_address_pool_association" "intfpoolassociation1" {
  network_interface_id    = azurerm_network_interface.firstif.id
  ip_configuration_name   = "edge1cloudeos1Intf0"
  backend_address_pool_id = azurerm_lb_backend_address_pool.pool1[0].id
}

resource "azurerm_lb_backend_address_pool" "pool1" {
  resource_group_name = var.static_rg_vnet_info["edge1"]["rg"]
  loadbalancer_id     = azurerm_lb.cloudedgelb.id
  name                = "CloudEOSPool1"
}