provider "azurerm" {
  skip_provider_registration = true
  features {}
}

provider "cloudeos" {
  cvaas_domain              = var.cvaas["domain"]
  cvaas_server              = var.cvaas["server"]
  service_account_web_token = var.cvaas["service_token"]
}

variable "username" {}
variable "password" {}

resource "cloudeos_topology" "topology" {
  topology_name         = var.topology
  bgp_asn               = "100-200"                 // Range of BGP ASN’s used for topology
  vtep_ip_cidr          = var.vtep_ip_cidr          // CIDR block for VTEP IPs on cloudeos
  terminattr_ip_cidr    = var.terminattr_ip_cidr    // Loopback IP range on cloudeos
  dps_controlplane_cidr = var.dps_controlplane_cidr // CIDR block for Dps Control Plane IPs on cloudeos
}

resource "cloudeos_clos" "clos" {
  name              = "${var.topology}-clos"
  topology_name     = cloudeos_topology.topology.topology_name
  cv_container_name = var.clos_cv_container
}

resource "cloudeos_wan" "wan" {
  name              = "${var.topology}-wan"
  topology_name     = cloudeos_topology.topology.topology_name
  cv_container_name = var.wan_cv_container
}

module "edge1" {
  source        = "../../../module/cloudeos/azure/rg"
  nsg_name      = "${var.topology}edge1Nsg"
  role          = "CloudEdge"
  rg_name       = var.static_rg_vnet_info["edge1"]["rg"]
  vnet_name     = var.static_rg_vnet_info["edge1"]["vnet"]
  topology_name = cloudeos_topology.topology.topology_name
  clos_name     = cloudeos_clos.clos.name
  wan_name      = cloudeos_wan.wan.name
  tags = {
    Name = "${var.topology}edge1"
  }
  availability_set = true
}

module "edge1Subnet" {
  source          = "../../../module/cloudeos/azure/subnet"
#  subnet_prefixes = var.subnet_info["edge1subnet"]["subnet_prefixes"]
  subnet_names    = var.subnet_info["edge1subnet"]["subnet_names"]
  vnet_name       = module.edge1.vnet_name
  vnet_id         = module.edge1.vnet_id
  rg_name         = module.edge1.rg_name
  topology_name   = module.edge1.topology_name
}

module "get_ips" {
  source = "ados1991/Get-IpAvailablesAddressesSubnet/azure"
  subscription = "f1592ec1-9735-4a9b-b3c0-ef9854674431"
  resource_group = module.edge1.rg_name
  vnet_name = module.edge1.vnet_name
  subnet_name = var.subnet_info["edge1subnet"]["subnet_names"][count.index]
  count = length(var.subnet_info["edge1subnet"]["subnet_names"])
}

module "azureedge1cloudeos1" {
  source        = "../../../module/cloudeos/azure/router"
  vpc_info      = module.edge1.vpc_info
  topology_name = module.edge1.topology_name
  role          = "CloudEdge"
  tags          = { "Name" : "${var.topology}Edge1cloudeos1" }
  storage_name  = lower("${var.topology}edge1cloudeos1store")
  subnetids = {
    "edge1cloudeos1Intf0" = module.edge1Subnet.vnet_subnets[0]
    "edge1cloudeos1Intf1" = module.edge1Subnet.vnet_subnets[1]
    "edge1cloudeos1Intf2" = module.edge1Subnet.vnet_subnets[4]
    "edge1cloudeos1Intf3" = module.edge1Subnet.vnet_subnets[5]
  }
  publicip_name   = var.cloudeos_info["edge1cloudeos1"]["publicip_name"]
  intf_names      = var.cloudeos_info["edge1cloudeos1"]["intf_names"]
  interface_types = var.cloudeos_info["edge1cloudeos1"]["interface_types"]

  availablity_set_id     = module.edge1.availability_set_id
  disk_name              = var.cloudeos_info["edge1cloudeos1"]["disk_name"]
  vm_size                = "Standard_D3_v2"
  private_ips            = {"0": [module.get_ips[0].ip_availables[0]], "1":  [module.get_ips[1].ip_availables[0]], "2": [module.get_ips[4].ip_availables[0]], "3":  [module.get_ips[5].ip_availables[0] ]}
  route_name             = var.cloudeos_info["edge1cloudeos1"]["route_name"]
  routetable_name        = var.cloudeos_info["edge1cloudeos1"]["routetable_name"]
  filename               = var.cloudeos_info["edge1cloudeos1"]["filename"]
  cloudeos_image_version = var.cloudeos_info["edge1cloudeos1"]["cloudeos_image_version"]
  cloudeos_image_name    = var.cloudeos_info["edge1cloudeos1"]["cloudeos_image_name"]
  cloudeos_image_offer   = var.cloudeos_info["edge1cloudeos1"]["cloudeos_image_offer"]
  admin_password         = var.password
  admin_username         = var.username
}

module "azureedge1cloudeos2" {
  source        = "../../../module/cloudeos/azure/router"
  vpc_info      = module.edge1.vpc_info
  topology_name = module.edge1.topology_name
  role          = "CloudEdge"
  tags          = { "Name" : "${var.topology}Edge1cloudeos2" }
  storage_name  = lower("${var.topology}edge1cloudeos2store")
  subnetids = {
    "edge1cloudeos2Intf0" = module.edge1Subnet.vnet_subnets[2]
    "edge1cloudeos2Intf1" = module.edge1Subnet.vnet_subnets[3]
    "edge1cloudeos2Intf2" = module.edge1Subnet.vnet_subnets[4]
    "edge1cloudeos2Intf3" = module.edge1Subnet.vnet_subnets[5]
  }
  availablity_set_id     = module.edge1.availability_set_id
  publicip_name          = var.cloudeos_info["edge1cloudeos2"]["publicip_name"]
  intf_names             = var.cloudeos_info["edge1cloudeos2"]["intf_names"]
  interface_types        = var.cloudeos_info["edge1cloudeos2"]["interface_types"]
  disk_name              = var.cloudeos_info["edge1cloudeos2"]["disk_name"]
  vm_size                = "Standard_D3_v2"
  private_ips            = {"0": [module.get_ips[2].ip_availables[0]], "1":  [module.get_ips[3].ip_availables[0]], "2": [module.get_ips[4].ip_availables[1]], "3":  [module.get_ips[5].ip_availables[1] ]}
  route_name             = var.cloudeos_info["edge1cloudeos2"]["route_name"]
  routetable_name        = var.cloudeos_info["edge1cloudeos2"]["routetable_name"]
  filename               = var.cloudeos_info["edge1cloudeos2"]["filename"]
  cloudeos_image_version = var.cloudeos_info["edge1cloudeos2"]["cloudeos_image_version"]
  cloudeos_image_name    = var.cloudeos_info["edge1cloudeos2"]["cloudeos_image_name"]
  cloudeos_image_offer   = var.cloudeos_info["edge1cloudeos2"]["cloudeos_image_offer"]
  admin_password         = var.password
  admin_username         = var.username
}

/*
module "azureRR1" {
  source = "../../../module/cloudeos/azure/router"
  role   = "CloudEdge"
  subnetids = {
    "RR1Intf0" = module.edge1Subnet.vnet_subnets[2]
  }
  vpc_info               = module.edge1.vpc_info
  topology_name          = module.edge1.topology_name
  publicip_name          = var.cloudeos_info["rr1"]["publicip_name"]
  intf_names             = var.cloudeos_info["rr1"]["intf_names"]
  interface_types        = var.cloudeos_info["rr1"]["interface_types"]
  tags                   = var.cloudeos_info["rr1"]["tags"]
  disk_name              = var.cloudeos_info["rr1"]["disk_name"]
  storage_name           = var.cloudeos_info["rr1"]["storage_name"]
  private_ips            = var.cloudeos_info["rr1"]["private_ips"]
  route_name             = var.cloudeos_info["rr1"]["route_name"]
  routetable_name        = var.cloudeos_info["rr1"]["routetable_name"]
  filename               = var.cloudeos_info["rr1"]["filename"]
  cloudeos_image_version = var.cloudeos_info["rr1"]["cloudeos_image_version"]
  cloudeos_image_sku     = var.cloudeos_info["rr1"]["cloudeos_image_sku"]
  is_rr                  = true
  admin_password         = var.password
  admin_username         = var.username
}
*/
