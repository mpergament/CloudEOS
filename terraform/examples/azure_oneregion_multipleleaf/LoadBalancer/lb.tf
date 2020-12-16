provider "azurerm" {
  skip_provider_registration = true
  features {}
}

locals {
  rg         = var.static_rg_vnet_info["edge1"]["rg"]
  vnet       = var.static_rg_vnet_info["edge1"]["vnet"]
  edge1subnets = ["edge1cloudeos1Intf0", "edge1cloudeos1Intf1", "edge1cloudeos1Intf2",
                  "edge1cloudeos1Intf3"/*, "edge1cloudeos1Intf4", "edge1cloudeos1Intf5",
                  "edge1cloudeos1Intf6", "edge1cloudeos1Intf7"*/]
  edge2subnets = ["edge1cloudeos2Intf0", "edge1cloudeos2Intf1", "edge1cloudeos2Intf2",
                  "edge1cloudeos2Intf3"/*, "edge1cloudeos2Intf4", "edge1cloudeos2Intf5",
                  "edge1cloudeos2Intf6", "edge1cloudeos2Intf7"*/]
}

data "azurerm_resource_group" "rg" {
  name       = local.rg
}

data "azurerm_virtual_network" "vnet" {
  name                = local.vnet
  resource_group_name = local.rg
}

data "azurerm_subnet" "subnet" {
  name                 = var.subnet_info["edge1subnet"]["subnet_names"][count.index]
  virtual_network_name = local.vnet
  resource_group_name  = local.rg
  count                = length(var.subnet_info["edge1subnet"]["subnet_names"])
}

data "azurerm_network_interface" "edge1ifs" {
  count                = length(local.edge1subnets)
  name                = local.edge1subnets[count.index]
  resource_group_name = local.rg
}

data "azurerm_network_interface" "edge2ifs" {
  count                = length(local.edge2subnets)
  name                = local.edge2subnets[count.index]
  resource_group_name = local.rg
}

resource "azurerm_lb" "cloudedgelb" {
  name                = "AMADEUS-TEST"
  location            = data.azurerm_virtual_network.vnet.location
  resource_group_name = local.rg
  sku                 = "Standard"
  frontend_ip_configuration {
    name      = "Amadeus-Onprem-DC"
    subnet_id = data.azurerm_subnet.subnet[2].id
  }
  frontend_ip_configuration {
    name      = "Amadeus-Spoke-DC"
    subnet_id = data.azurerm_subnet.subnet[3].id
  }
/*  frontend_ip_configuration {
    name      = "Amadeus-Onprem-EXT"
    subnet_id = data.azurerm_subnet.subnet[4].id
  }
  frontend_ip_configuration {
    name      = "Amadeus-Spoke-EXT"
    subnet_id = data.azurerm_subnet.subnet[5].id
  }
  frontend_ip_configuration {
    name      = "Amadeus-Onprem-INT"
    subnet_id = data.azurerm_subnet.subnet[6].id
  }
  frontend_ip_configuration {
    name      = "Amadeus-Spoke-INT"
    subnet_id = data.azurerm_subnet.subnet[7].id
  } */
}

resource "azurerm_lb_rule" "rule1" {
  resource_group_name            = local.rg
  loadbalancer_id                = azurerm_lb.cloudedgelb.id
  name                           = "rule1"
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "Amadeus-Onprem-DC"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.pool1.id
  probe_id                       = azurerm_lb_probe.probe.id
  load_distribution              = "Default"
}

resource "azurerm_lb_probe" "probe" {
  resource_group_name = local.rg
  loadbalancer_id     = azurerm_lb.cloudedgelb.id
  name                = "ssh-probe"
  port                = 22
  protocol            = "Tcp"
}

resource "azurerm_network_interface_backend_address_pool_association" "intfpool1association1" {
  network_interface_id    = data.azurerm_network_interface.edge1ifs[2].id
  ip_configuration_name   = local.edge1subnets[2]
  backend_address_pool_id = azurerm_lb_backend_address_pool.pool1.id
}

resource "azurerm_network_interface_backend_address_pool_association" "intfpool1association2" {
  network_interface_id    = data.azurerm_network_interface.edge2ifs[2].id
  ip_configuration_name   = local.edge2subnets[2]
  backend_address_pool_id = azurerm_lb_backend_address_pool.pool1.id
}

resource "azurerm_lb_backend_address_pool" "pool1" {
  resource_group_name = local.rg
  loadbalancer_id     = azurerm_lb.cloudedgelb.id
  name                = "Amadeus-Onprem-DC-Backend"
}

resource "azurerm_network_interface_backend_address_pool_association" "intfpool2association1" {
  network_interface_id    = data.azurerm_network_interface.edge1ifs[3].id
  ip_configuration_name   = local.edge1subnets[3]
  backend_address_pool_id = azurerm_lb_backend_address_pool.pool1.id
}

resource "azurerm_network_interface_backend_address_pool_association" "intfpool2association2" {
  network_interface_id    = data.azurerm_network_interface.edge2ifs[3].id
  ip_configuration_name   = local.edge2subnets[3]
  backend_address_pool_id = azurerm_lb_backend_address_pool.pool2.id
}

resource "azurerm_lb_backend_address_pool" "pool2" {
  resource_group_name = local.rg
  loadbalancer_id     = azurerm_lb.cloudedgelb.id
  name                = "Amadeus-Onprem-Spoke-Backend"
}