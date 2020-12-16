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