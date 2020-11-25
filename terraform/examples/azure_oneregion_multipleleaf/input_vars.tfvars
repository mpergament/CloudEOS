## PLEASE CUSTOMIZE file for your deployment
## Search "mandatory" for parameters that need to be customized before deployment
topology = "tscl" #mandatory

## Get service_token from Arista Contact and replace empty string below
cvaas = {
  domain : "apiserver.cv-staging.corp.arista.io",
  server : "www.cv-staging.corp.arista.io",
  service_token : "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJkaWQiOjExOTU2LCJkc24iOiJ0cyIsImRzdCI6ImFjY291bnQiLCJzaWQiOiIwZTU3MTZiNmQ1NGE1MzljMThiNWMxZmU2YWExMDFhYzZmMzYyZDA2ZTc0Y2I1MmE1NWQ0YTRmNjIwMmQyOTQwLTZSZnUzZWZpMWxlQzhBRzJxYXhyOF9fd09EOEVOZmdQWGIxUzNBWnUifQ.qjjF9jReDopqUuhVqufeULX1bvEQbf5PBUWoR8WQrZcABwtN1ukAGHKowp7Do1_jxQRWPv9KFtjopw_2iCAJcQ" #mandatory
}

## CloudEdge network requires three subnets for control plane.
vtep_ip_cidr          = "24.0.1.0/24" // CIDR block for VTEP IPs
terminattr_ip_cidr    = "24.0.2.0/24" // Loopback IP range for CloudVision connectivity
dps_controlplane_cidr = "24.0.3.0/24" // CIDR block for VXLAN/Dps Control Plane IPs

## CloudVision container names - they need to be created on www.arista.io/cv
## before deployment. Steps to create containers on CloudVision are in
## "CloudEdgedev MultiCloud Deployment Guide"
clos_cv_container = "amadeus_poc"
wan_cv_container  = "amadeus_poc"

azure_regions = {
  region1 : "westus2",
}

static_rg_vnet_info = {
  edge1: {
    rg = "amadeus_hub_rg"
    vnet = "amadeus_hub"
  }
  azureLeaf1: {
    rg = "amadeus_spoke1_rg"
    vnet = "amadeus_spoke1_vnet"
  }
  azureLeaf2: {
    rg = "amadeus_spoke2_rg"
    vnet = "amadeus_spoke2_vnet"
  }
}

subnet_info = {
  edge1subnet : {
    subnet_prefixes = ["13.0.0.0/24", "13.0.1.0/24", "13.0.2.0/24", "13.0.3.0/24", "13.0.10.0/24", "13.0.11.0/24"]
    subnet_names    = ["edge1Subnet0", "edge1Subnet1", "edge1Subnet2", "edge1Subnet3", "edge1Subnet4", "edge1Subnet5"]
  }
  leaf1subnet = {
    subnet_prefixes = ["18.0.0.0/24", "18.0.1.0/24", "18.0.2.0/24", "18.0.3.0/24"]
    subnet_names    = ["leaf1Subnet0", "leaf1Subnet1", "leaf1Subnet2", "leaf1Subnet3"]
  }
  leaf2subnet = {
    subnet_prefixes = ["19.0.0.0/24", "19.0.1.0/24", "19.0.2.0/24", "19.0.3.0/24"]
    subnet_names    = ["leaf2Subnet0", "leaf2Subnet1", "leaf2Subnet2", "leaf2Subnet3"]
  }
}

cloudeos_info = {
  edge1cloudeos1 : {
    publicip_name = "edge1cloudeos1Pip"
    intf_names    = ["edge1cloudeos1Intf0", "edge1cloudeos1Intf1", "edge1cloudeos1Intf2", "edge1cloudeos1Intf3"]
    interface_types = {
      "edge1cloudeos1Intf0" = "public"
      "edge1cloudeos1Intf1" = "internal"
      "edge1cloudeos1Intf2" = "internal"
      "edge1cloudeos1Intf3" = "internal"
    }
    disk_name              = "edge1cloudeos1disk"
    private_ips            = { "0" : ["13.0.0.101"], "1" : ["13.0.1.101"], "2" : ["13.0.10.101"], "3" : ["13.0.11.101"] }
    route_name             = "azedge1Rt"
    routetable_name        = "azedge1RtTable"
    filename               = "../../../userdata/eos_ipsec_config.tpl"
    cloudeos_image_version = "4.24.01"
    cloudeos_image_name    = "cloudeos-4_24_0-payg-free"
    cloudeos_image_offer   = "cloudeos-router-payg"
  }
  edge1cloudeos2 : {
    publicip_name = "edge1cloudeos2Pip"
    intf_names    = ["edge1cloudeos2Intf0", "edge1cloudeos2Intf1", "edge1cloudeos2Intf2", "edge1cloudeos2Intf3"]
    interface_types = {
      "edge1cloudeos2Intf0" = "public"
      "edge1cloudeos2Intf1" = "internal"
      "edge1cloudeos2Intf2" = "internal"
      "edge1cloudeos2Intf3" = "internal"
    }
    disk_name              = "edge1cloudeos2disk"
    private_ips            = { "0" : ["13.0.2.101"], "1" : ["13.0.3.101"], "2" : ["13.0.10.102"], "3" : ["13.0.11.102"] }
    route_name             = "azedge1cloudeos2Rt"
    routetable_name        = "azedge1cloudeos2RtTable"
    filename               = "../../../userdata/eos_ipsec_config.tpl"
    cloudeos_image_version = "4.24.01"
    cloudeos_image_name    = "cloudeos-4_24_0-payg-free"
    cloudeos_image_offer   = "cloudeos-router-payg"

  }
  rr1 = {
    publicip_name = "RR1Pip"
    intf_names    = ["RR1Intf0"]
    interface_types = {
      "RR1Intf0" = "public"
    }
    tags                   = { "Name" : "azedgeRR1", "autoshutdown" : "no", "autostop" : "no" }
    disk_name              = "adRR1disk"
    storage_name           = "rr1storage"
    private_ips            = { "0" : ["12.0.4.101"] }
    route_name             = "adedge1Rt"
    routetable_name        = "adedge1RtTable"
    filename               = "../../../userdata/eos_ipsec_config.tpl"
    cloudeos_image_version = "4.24.01"
    cloudeos_image_name    = "cloudeos-4_24_0-payg-free"
    cloudeos_image_offer   = "cloudeos-router-payg"
  }
  leaf1cloudeos1 = {
    cloudeos_image_version = "4.24.01"
    cloudeos_image_name    = "cloudeos-4_24_0-payg-free"
    cloudeos_image_offer   = "cloudeos-router-payg"
    intf_names             = ["leaf1cloudeos1Intf0", "leaf1cloudeos1Intf1"]
    interface_types = {
      "leaf1cloudeos1Intf0" = "internal"
      "leaf1cloudeos1Intf1" = "private"
    }
    private_ips       = { "0" : ["18.0.0.101"], "1" : ["18.0.1.101"] }
    tags              = { "Name" : "azleaf1cloudeos1", "Cnps" : "dev" }
    disk_name         = "leaf1cloudeos1disk"
    storage_name      = "azleaf1cloudeos1storage"
    route_name        = "leaf1Rt1"
    routetable_name   = "leaf1RtTable1"
    cloud_ha          = "leaf1"
    filename          = "../../../userdata/eos_ipsec_config.tpl"
    availability_zone = [2]

  }
  leaf1cloudeos2 = {
    cloudeos_image_version = "4.24.01"
    cloudeos_image_name    = "cloudeos-4_24_0-payg-free"
    cloudeos_image_offer   = "cloudeos-router-payg"
    intf_names             = ["leaf1cloudeos2Intf0", "leaf1cloudeos2Intf1"]
    interface_types = {
      "leaf1cloudeos2Intf0" = "internal"
      "leaf1cloudeos2Intf1" = "private"
    }
    private_ips       = { "0" : ["18.0.2.101"], "1" : ["18.0.3.101"] }
    tags              = { "Name" : "azleaf1cloudeos2", "Cnps" : "dev" }
    disk_name         = "leaf1cloudeos2disk"
    route_name        = "leaf1cloudeos2Rt1"
    routetable_name   = "leaf1cloudeos2RtTable1"
    cloud_ha          = "leaf1"
    filename          = "../../../userdata/eos_ipsec_config.tpl"
    availability_zone = [3]
  }
  leaf2cloudeos1 = {
    intf_names = ["leaf2cloudeos1Intf0", "leaf2cloudeos1Intf1"]
    interface_types = {
      "leaf2cloudeos1Intf0" = "internal"
      "leaf2cloudeos1Intf1" = "private"
    }
    availability_zone      = [2]
    private_ips            = { "0" : ["19.0.0.101"], "1" : ["19.0.1.101"] }
    disk_name              = "leaf2cloudeos1disk"
    storage_name           = "leaf2cloudeos1storage"
    route_name             = "leaf2Rt1"
    routetable_name        = "leaf2RtTable1"
    cloud_ha               = "leaf2"
    cloudeos_image_version = "4.24.01"
    cloudeos_image_name    = "cloudeos-4_24_0-payg-free"
    cloudeos_image_offer   = "cloudeos-router-payg"
    filename               = "../../../userdata/eos_ipsec_config.tpl"
  }
  leaf2cloudeos2 = {
    intf_names = ["leaf2cloudeos2Intf0", "leaf2cloudeos2Intf1"]
    interface_types = {
      "leaf2cloudeos2Intf0" = "internal"
      "leaf2cloudeos2Intf1" = "private"
    }
    availability_zone      = [3]
    private_ips            = { "0" : ["19.0.2.101"], "1" : ["19.0.3.101"] }
    disk_name              = "leaf2cloudeos2disk"
    route_name             = "leaf2cloudeos2Rt1"
    routetable_name        = "leaf2cloudeos2RtTable1"
    cloud_ha               = "leaf2"
    cloudeos_image_version = "4.24.01"
    cloudeos_image_name    = "cloudeos-4_24_0-payg-free"
    cloudeos_image_offer   = "cloudeos-router-payg"
    filename               = "../../../userdata/eos_ipsec_config.tpl"
  }
}


