output "vnet_id" {
  description = "The id of the  vNet"
  value       = data.azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "The Name of the  vNet"
  value       = data.azurerm_virtual_network.vnet.name
}

output "rg_name" {
  description = "The Name of the  RG"
  value       = data.azurerm_resource_group.rg.name
}

output "vnet_location" {
  description = "The location of the  vNet"
  value       = data.azurerm_virtual_network.vnet.location
}

output "rg_location" {
  description = "The location of the  vNet"
  value       = data.azurerm_resource_group.rg.location
}

output "vnet_address_space" {
  description = "The address space of the  vNet"
  value       = data.azurerm_virtual_network.vnet.address_space
}

output "azurerm_subnet" {
  description = "The address space of the  vNet"
  value       = data.azurerm_subnet.subnet[count.index].id
  count       = length(data.azurerm_subnet.subnet)
}