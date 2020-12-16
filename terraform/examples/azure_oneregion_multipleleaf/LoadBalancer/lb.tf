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

resource "azurerm_lb" "leafha_ilb" {
  name                = "AMADEUS-TEST"
  location            = data.azurerm_virtual_network.vnet.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name      = "Amadeus-IP1"
    subnet_id = data.azurerm_subnet.subnet[0].id
  }
}