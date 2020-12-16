provider "azurerm" {
  skip_provider_registration = true
  features {}
}

data "azurerm_resource_group" "rg" {
  name       = var.rg_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.rg_name
}

data "azurerm_subnet" "subnet" {
  name                 = var.subnet_info["edge1subnet"]["subnet_names"][count.index]
  virtual_network_name = var.vnet_name
  resource_group_name  = var.rg_name
  count                = length(var.subnet_info["edge1subnet"]["subnet_names"])
}