// Copyright (c) 2020 Arista Networks, Inc.
// Use of this source code is governed by the Apache License 2.0
// that can be found in the LICENSE file.
module "globals" {
  source            = "../../../module/arista/common"
  topology          = var.topology
  keypair_name      = var.keypair_name
  cvaas             = var.cvaas
  instance_type     = var.instance_type
  aws_regions       = var.aws_regions
  eos_amis          = var.eos_amis
  availability_zone = var.availability_zone
  host_amis         = var.host_amis
}

provider "arista" {
  cvaas_domain              = module.globals.cvaas["domain"]
  cvaas_username            = module.globals.cvaas["username"]
  cvaas_server              = module.globals.cvaas["server"]
  service_account_web_token = module.globals.cvaas["service_token"]
}

//================= Leaf1 CloudEOS1===============================
module "Leaf1Vpc" {
  source        = "../../../module/arista/aws/vpc"
  topology_name = module.globals.topology
  clos_name     = "${module.globals.topology}-clos"
  role          = "CloudLeaf"
  cidr_block    = ["101.2.0.0/16"]
  tags = {
    Name = "${module.globals.topology}-Leaf1Vpc"
    Cnps = "dev"
  }
  region = module.globals.aws_regions["region2"]
}

module "Leaf1Subnet" {
  source = "../../../module/arista/aws/subnet"
  subnet_zones = {
    "101.2.0.0/24" = lookup(module.globals.availability_zone[module.Leaf1Vpc.region], "zone1", "")
    "101.2.1.0/24" = lookup(module.globals.availability_zone[module.Leaf1Vpc.region], "zone1", "")
    "101.2.2.0/24" = lookup(module.globals.availability_zone[module.Leaf1Vpc.region], "zone2", "")
    "101.2.3.0/24" = lookup(module.globals.availability_zone[module.Leaf1Vpc.region], "zone2", "")
  }
  subnet_names = {
    "101.2.0.0/24" = "${module.globals.topology}-Leaf1Subnet0"
    "101.2.1.0/24" = "${module.globals.topology}-Leaf1Subnet1"
    "101.2.2.0/24" = "${module.globals.topology}-Leaf1Subnet2"
    "101.2.3.0/24" = "${module.globals.topology}-Leaf1Subnet3"
  }
  vpc_id        = module.Leaf1Vpc.vpc_id[0]
  topology_name = module.Leaf1Vpc.topology_name
  region        = module.Leaf1Vpc.region
}

module "Leaf1CloudEOS1" {
  source        = "../../../module/arista/aws/cloudEOS"
  role          = "CloudLeaf"
  topology_name = module.Leaf1Vpc.topology_name
  cloudeos_ami  = module.globals.eos_amis[module.Leaf1Vpc.region]
  keypair_name  = module.globals.keypair_name[module.Leaf1Vpc.region]
  vpc_info      = module.Leaf1Vpc.vpc_info
  intf_names = [
    "${module.globals.topology}-Leaf1CloudEOS1Intf0",
    "${module.globals.topology}-Leaf1CloudEOS1Intf1"
  ]
  interface_types = {
    "${module.globals.topology}-Leaf1CloudEOS1Intf0" = "internal"
    "${module.globals.topology}-Leaf1CloudEOS1Intf1" = "private"
  }
  subnetids = {
    "${module.globals.topology}-Leaf1CloudEOS1Intf0" = module.Leaf1Subnet.vpc_subnets[0]
    "${module.globals.topology}-Leaf1CloudEOS1Intf1" = module.Leaf1Subnet.vpc_subnets[1]
  }
  private_ips       = { "0" : ["101.2.0.101"], "1" : ["101.2.1.101"] }
  availability_zone = lookup(module.globals.availability_zone[module.Leaf1Vpc.region], "zone1", "")
  region            = module.Leaf1Vpc.region
  tags = {
    "Name" = "${module.globals.topology}-Leaf1CloudEOS1"
    "Cnps" = "dev"
  }
  cloud_ha             = "leaf1"
  primary              = true
  iam_instance_profile = var.aws_iam_instance_profile
  filename             = "../../../userdata/eos_ipsec_config.tpl"
}

module "Leaf1CloudEOS2" {
  source        = "../../../module/arista/aws/cloudEOS"
  role          = "CloudLeaf"
  topology_name = module.Leaf1Vpc.topology_name
  cloudeos_ami  = module.globals.eos_amis[module.Leaf1Vpc.region]
  keypair_name  = module.globals.keypair_name[module.Leaf1Vpc.region]
  vpc_info      = module.Leaf1Vpc.vpc_info
  intf_names = [
    "${module.globals.topology}-Leaf1CloudEOS2Intf0",
    "${module.globals.topology}-Leaf1CloudEOS2Intf1"
  ]
  interface_types = {
    "${module.globals.topology}-Leaf1CloudEOS2Intf0" = "internal"
    "${module.globals.topology}-Leaf1CloudEOS2Intf1" = "private"
  }
  subnetids = {
    "${module.globals.topology}-Leaf1CloudEOS2Intf0" = module.Leaf1Subnet.vpc_subnets[2]
    "${module.globals.topology}-Leaf1CloudEOS2Intf1" = module.Leaf1Subnet.vpc_subnets[3]
  }
  private_ips       = { "0" : ["101.2.2.101"], "1" : ["101.2.3.101"] }
  availability_zone = lookup(module.globals.availability_zone[module.Leaf1Vpc.region], "zone2", "")
  region            = module.Leaf1Vpc.region
  tags = {
    "Name" = "${module.globals.topology}-Leaf1CloudEOS2"
    "Cnps" = "dev"
  }
  cloud_ha                   = "leaf1"
  internal_route_table_id    = module.Leaf1CloudEOS1.route_table_internal
  primary_internal_subnetids = [module.Leaf1Subnet.vpc_subnets[0]]
  iam_instance_profile       = var.aws_iam_instance_profile
  filename                   = "../../../userdata/eos_ipsec_config.tpl"
}

module "Leaf1host1" {
  region        = module.globals.aws_regions["region2"]
  source        = "../../../module/arista/aws/host"
  ami           = module.globals.host_amis[module.Leaf1Vpc.region]
  instance_type = "c5.xlarge"
  keypair_name  = module.globals.keypair_name[module.Leaf1Vpc.region]
  subnet_id     = module.Leaf1Subnet.vpc_subnets[1]
  private_ips   = ["101.2.1.102"]
  tags = {
    "Name" = "${module.globals.topology}-Leaf1host"
  }
}

// Leaf2
module "Leaf2Vpc" {
  source        = "../../../module/arista/aws/vpc"
  topology_name = module.globals.topology
  clos_name     = "${module.globals.topology}-clos"
  role          = "CloudLeaf"
  cidr_block    = ["102.2.0.0/16"]
  tags = {
    Name = "${module.globals.topology}-Leaf2Vpc"
    Cnps = "prod"
  }
  region = module.globals.aws_regions["region2"]
}

module "Leaf2Subnet" {
  source = "../../../module/arista/aws/subnet"
  subnet_zones = {
    "102.2.0.0/24" = lookup(module.globals.availability_zone[module.Leaf2Vpc.region], "zone1", "")
    "102.2.1.0/24" = lookup(module.globals.availability_zone[module.Leaf2Vpc.region], "zone1", "")
    "102.2.2.0/24" = lookup(module.globals.availability_zone[module.Leaf2Vpc.region], "zone2", "")
    "102.2.3.0/24" = lookup(module.globals.availability_zone[module.Leaf2Vpc.region], "zone2", "")
  }
  subnet_names = {
    "102.2.0.0/24" = "${module.globals.topology}-Leaf2Subnet0"
    "102.2.1.0/24" = "${module.globals.topology}-Leaf2Subnet1"
    "102.2.2.0/24" = "${module.globals.topology}-Leaf2Subnet2"
    "102.2.3.0/24" = "${module.globals.topology}-Leaf2Subnet3"
  }
  vpc_id        = module.Leaf2Vpc.vpc_id[0]
  topology_name = module.Leaf2Vpc.topology_name
  region        = module.Leaf2Vpc.region
}

module "Leaf2CloudEOS1" {
  source        = "../../../module/arista/aws/cloudEOS"
  role          = "CloudLeaf"
  topology_name = module.Leaf2Vpc.topology_name
  cloudeos_ami  = module.globals.eos_amis[module.Leaf2Vpc.region]
  keypair_name  = module.globals.keypair_name[module.Leaf2Vpc.region]
  vpc_info      = module.Leaf2Vpc.vpc_info
  intf_names = [
    "${module.globals.topology}-Leaf2CloudEOS1Intf0",
    "${module.globals.topology}-Leaf2CloudEOS1Intf1"
  ]
  interface_types = {
    "${module.globals.topology}-Leaf2CloudEOS1Intf0" = "internal"
    "${module.globals.topology}-Leaf2CloudEOS1Intf1" = "private"
  }
  subnetids = {
    "${module.globals.topology}-Leaf2CloudEOS1Intf0" = module.Leaf2Subnet.vpc_subnets[0]
    "${module.globals.topology}-Leaf2CloudEOS1Intf1" = module.Leaf2Subnet.vpc_subnets[1]
  }
  private_ips       = { "0" : ["102.2.0.101"], "1" : ["102.2.1.101"] }
  availability_zone = lookup(module.globals.availability_zone[module.Leaf2Vpc.region], "zone1", "")
  region            = module.Leaf2Vpc.region
  tags = {
    "Name" = "${module.globals.topology}-Leaf2CloudEOS1"
    "Cnps" = "prod"
  }
  cloud_ha             = "leaf2"
  primary              = true
  iam_instance_profile = var.aws_iam_instance_profile
  filename             = "../../../userdata/eos_ipsec_config.tpl"
}

module "Leaf2CloudEOS2" {
  source        = "../../../module/arista/aws/cloudEOS"
  role          = "CloudLeaf"
  topology_name = module.Leaf2Vpc.topology_name
  cloudeos_ami  = module.globals.eos_amis[module.Leaf2Vpc.region]
  keypair_name  = module.globals.keypair_name[module.Leaf2Vpc.region]
  vpc_info      = module.Leaf2Vpc.vpc_info
  intf_names = [
    "${module.globals.topology}-Leaf2CloudEOS2Intf0",
    "${module.globals.topology}-Leaf2CloudEOS2Intf1"
  ]
  interface_types = {
    "${module.globals.topology}-Leaf2CloudEOS2Intf0" = "internal"
    "${module.globals.topology}-Leaf2CloudEOS2Intf1" = "private"
  }
  subnetids = {
    "${module.globals.topology}-Leaf2CloudEOS2Intf0" = module.Leaf2Subnet.vpc_subnets[2]
    "${module.globals.topology}-Leaf2CloudEOS2Intf1" = module.Leaf2Subnet.vpc_subnets[3]
  }
  private_ips       = { "0" : ["102.2.2.101"], "1" : ["102.2.3.101"] }
  availability_zone = lookup(module.globals.availability_zone[module.Leaf2Vpc.region], "zone2", "")
  region            = module.Leaf2Vpc.region
  tags = {
    "Name" = "${module.globals.topology}-Leaf2CloudEOS2"
    "Cnps" = "prod"
  }
  cloud_ha                   = "leaf2"
  internal_route_table_id    = module.Leaf2CloudEOS1.route_table_internal
  primary_internal_subnetids = [module.Leaf2Subnet.vpc_subnets[0]]
  iam_instance_profile       = var.aws_iam_instance_profile
  filename                   = "../../../userdata/eos_ipsec_config.tpl"
}

//Leaf3
module "Leaf3Vpc" {
  source        = "../../../module/arista/aws/vpc"
  topology_name = module.globals.topology
  clos_name     = "${module.globals.topology}-clos"
  role          = "CloudLeaf"
  cidr_block    = ["103.2.0.0/16"]
  tags = {
    Name = "${module.globals.topology}-Leaf3Vpc"
    Cnps = "dev"
  }
  region = module.globals.aws_regions["region2"]
}

module "Leaf3Subnet" {
  source = "../../../module/arista/aws/subnet"
  subnet_zones = {
    "103.2.0.0/24" = lookup(module.globals.availability_zone[module.Leaf3Vpc.region], "zone1", "")
    "103.2.1.0/24" = lookup(module.globals.availability_zone[module.Leaf3Vpc.region], "zone1", "")
    "103.2.2.0/24" = lookup(module.globals.availability_zone[module.Leaf3Vpc.region], "zone2", "")
    "103.2.3.0/24" = lookup(module.globals.availability_zone[module.Leaf3Vpc.region], "zone2", "")
  }
  subnet_names = {
    "103.2.0.0/24" = "${module.globals.topology}-Leaf3Subnet0"
    "103.2.1.0/24" = "${module.globals.topology}-Leaf3Subnet1"
    "103.2.2.0/24" = "${module.globals.topology}-Leaf3Subnet2"
    "103.2.3.0/24" = "${module.globals.topology}-Leaf3Subnet3"
  }
  vpc_id        = module.Leaf3Vpc.vpc_id[0]
  topology_name = module.Leaf3Vpc.topology_name
  region        = module.Leaf3Vpc.region
}

module "Leaf3CloudEOS1" {
  source        = "../../../module/arista/aws/cloudEOS"
  role          = "CloudLeaf"
  topology_name = module.Leaf3Vpc.topology_name
  cloudeos_ami  = module.globals.eos_amis[module.Leaf3Vpc.region]
  keypair_name  = module.globals.keypair_name[module.Leaf3Vpc.region]
  vpc_info      = module.Leaf3Vpc.vpc_info
  intf_names = [
    "${module.globals.topology}-Leaf3CloudEOS1Intf0",
    "${module.globals.topology}-Leaf3CloudEOS1Intf1"
  ]
  interface_types = {
    "${module.globals.topology}-Leaf3CloudEOS1Intf0" = "internal"
    "${module.globals.topology}-Leaf3CloudEOS1Intf1" = "private"
  }
  subnetids = {
    "${module.globals.topology}-Leaf3CloudEOS1Intf0" = module.Leaf3Subnet.vpc_subnets[0]
    "${module.globals.topology}-Leaf3CloudEOS1Intf1" = module.Leaf3Subnet.vpc_subnets[1]
  }
  private_ips       = { "0" : ["103.2.0.101"], "1" : ["103.2.1.101"] }
  availability_zone = lookup(module.globals.availability_zone[module.Leaf3Vpc.region], "zone1", "")
  region            = module.Leaf3Vpc.region
  tags = {
    "Name" = "${module.globals.topology}-Leaf3CloudEOS1"
    "Cnps" = "dev"
  }
  cloud_ha             = "leaf3"
  primary              = true
  iam_instance_profile = var.aws_iam_instance_profile
  filename             = "../../../userdata/eos_ipsec_config.tpl"
}

module "Leaf3CloudEOS2" {
  source        = "../../../module/arista/aws/cloudEOS"
  role          = "CloudLeaf"
  topology_name = module.Leaf3Vpc.topology_name
  cloudeos_ami  = module.globals.eos_amis[module.Leaf3Vpc.region]
  keypair_name  = module.globals.keypair_name[module.Leaf3Vpc.region]
  vpc_info      = module.Leaf3Vpc.vpc_info
  intf_names = [
    "${module.globals.topology}-Leaf3CloudEOS2Intf0",
    "${module.globals.topology}-Leaf3CloudEOS2Intf1"
  ]
  interface_types = {
    "${module.globals.topology}-Leaf3CloudEOS2Intf0" = "internal"
    "${module.globals.topology}-Leaf3CloudEOS2Intf1" = "private"
  }
  subnetids = {
    "${module.globals.topology}-Leaf3CloudEOS2Intf0" = module.Leaf3Subnet.vpc_subnets[2]
    "${module.globals.topology}-Leaf3CloudEOS2Intf1" = module.Leaf3Subnet.vpc_subnets[3]
  }
  private_ips       = { "0" : ["103.2.2.101"], "1" : ["103.2.3.101"] }
  availability_zone = lookup(module.globals.availability_zone[module.Leaf3Vpc.region], "zone2", "")
  region            = module.Leaf3Vpc.region
  tags = {
    "Name" = "${module.globals.topology}-Leaf3CloudEOS2"
    "Cnps" = "dev"
  }
  cloud_ha                   = "leaf3"
  internal_route_table_id    = module.Leaf3CloudEOS1.route_table_internal
  primary_internal_subnetids = [module.Leaf3Subnet.vpc_subnets[0]]
  iam_instance_profile       = var.aws_iam_instance_profile
  filename                   = "../../../userdata/eos_ipsec_config.tpl"
}

module "Leaf3host1" {
  region        = module.globals.aws_regions["region2"]
  source        = "../../../module/arista/aws/host"
  ami           = module.globals.host_amis[module.Leaf3Vpc.region]
  instance_type = "c5.xlarge"
  keypair_name  = module.globals.keypair_name[module.Leaf3Vpc.region]
  subnet_id     = module.Leaf3Subnet.vpc_subnets[1]
  private_ips   = ["103.2.1.102"]
  tags = {
    "Name" = "${module.globals.topology}-Leaf3host"
  }
}

//Leaf4
module "Leaf4Vpc" {
  source        = "../../../module/arista/aws/vpc"
  topology_name = module.globals.topology
  clos_name     = "${module.globals.topology}-clos"
  role          = "CloudLeaf"
  cidr_block    = ["104.2.0.0/16"]
  tags = {
    Name = "${module.globals.topology}-Leaf4Vpc"
    Cnps = "prod"
  }
  region = module.globals.aws_regions["region2"]
}

module "Leaf4Subnet" {
  source = "../../../module/arista/aws/subnet"
  subnet_zones = {
    "104.2.0.0/24" = lookup(module.globals.availability_zone[module.Leaf4Vpc.region], "zone1", "")
    "104.2.1.0/24" = lookup(module.globals.availability_zone[module.Leaf4Vpc.region], "zone1", "")
    "104.2.2.0/24" = lookup(module.globals.availability_zone[module.Leaf4Vpc.region], "zone2", "")
    "104.2.3.0/24" = lookup(module.globals.availability_zone[module.Leaf4Vpc.region], "zone2", "")
  }
  subnet_names = {
    "104.2.0.0/24" = "${module.globals.topology}-Leaf4Subnet0"
    "104.2.1.0/24" = "${module.globals.topology}-Leaf4Subnet1"
    "104.2.2.0/24" = "${module.globals.topology}-Leaf4Subnet2"
    "104.2.3.0/24" = "${module.globals.topology}-Leaf4Subnet3"
  }
  vpc_id        = module.Leaf4Vpc.vpc_id[0]
  topology_name = module.Leaf4Vpc.topology_name
  region        = module.Leaf4Vpc.region
}

module "Leaf4CloudEOS1" {
  source        = "../../../module/arista/aws/cloudEOS"
  role          = "CloudLeaf"
  topology_name = module.Leaf4Vpc.topology_name
  cloudeos_ami  = module.globals.eos_amis[module.Leaf4Vpc.region]
  keypair_name  = module.globals.keypair_name[module.Leaf4Vpc.region]
  vpc_info      = module.Leaf4Vpc.vpc_info
  intf_names = [
    "${module.globals.topology}-Leaf4CloudEOS1Intf0",
    "${module.globals.topology}-Leaf4CloudEOS1Intf1"
  ]
  interface_types = {
    "${module.globals.topology}-Leaf4CloudEOS1Intf0" = "internal"
    "${module.globals.topology}-Leaf4CloudEOS1Intf1" = "private"
  }
  subnetids = {
    "${module.globals.topology}-Leaf4CloudEOS1Intf0" = module.Leaf4Subnet.vpc_subnets[0]
    "${module.globals.topology}-Leaf4CloudEOS1Intf1" = module.Leaf4Subnet.vpc_subnets[1]
  }
  private_ips       = { "0" : ["104.2.0.101"], "1" : ["104.2.1.101"] }
  availability_zone = lookup(module.globals.availability_zone[module.Leaf4Vpc.region], "zone1", "")
  region            = module.Leaf4Vpc.region
  tags = {
    "Name" = "${module.globals.topology}-Leaf4CloudEOS1"
    "Cnps" = "prod"
  }
  cloud_ha             = "leaf4"
  primary              = true
  iam_instance_profile = var.aws_iam_instance_profile
  filename             = "../../../userdata/eos_ipsec_config.tpl"
}

module "Leaf4CloudEOS2" {
  source        = "../../../module/arista/aws/cloudEOS"
  role          = "CloudLeaf"
  topology_name = module.Leaf4Vpc.topology_name
  cloudeos_ami  = module.globals.eos_amis[module.Leaf4Vpc.region]
  keypair_name  = module.globals.keypair_name[module.Leaf4Vpc.region]
  vpc_info      = module.Leaf4Vpc.vpc_info
  intf_names = [
    "${module.globals.topology}-Leaf4CloudEOS2Intf0",
    "${module.globals.topology}-Leaf4CloudEOS2Intf1"
  ]
  interface_types = {
    "${module.globals.topology}-Leaf4CloudEOS2Intf0" = "internal"
    "${module.globals.topology}-Leaf4CloudEOS2Intf1" = "private"
  }
  subnetids = {
    "${module.globals.topology}-Leaf4CloudEOS2Intf0" = module.Leaf4Subnet.vpc_subnets[2]
    "${module.globals.topology}-Leaf4CloudEOS2Intf1" = module.Leaf4Subnet.vpc_subnets[3]
  }
  private_ips       = { "0" : ["104.2.2.101"], "1" : ["104.2.3.101"] }
  availability_zone = lookup(module.globals.availability_zone[module.Leaf4Vpc.region], "zone2", "")
  region            = module.Leaf4Vpc.region
  tags = {
    "Name" = "${module.globals.topology}-Leaf4CloudEOS2"
    "Cnps" = "prod"
  }
  cloud_ha                   = "leaf4"
  internal_route_table_id    = module.Leaf4CloudEOS1.route_table_internal
  primary_internal_subnetids = [module.Leaf4Subnet.vpc_subnets[0]]
  iam_instance_profile       = var.aws_iam_instance_profile
  filename                   = "../../../userdata/eos_ipsec_config.tpl"
}

/*
//Leaf5
module "Leaf5Vpc" {
  source         = "../../../module/arista/aws/vpc"
  topology_name  = module.globals.topology
  clos_name      = "${module.globals.topology}-clos"
  role           = "CloudLeaf"
  cidr_block     = ["105.2.0.0/16"]
  tags = {
    Name = "${module.globals.topology}-Leaf5Vpc"
    Cnps = "prod"
  }
  region = module.globals.aws_regions["region2"]
}

module "Leaf5Subnet" {
  source = "../../../module/arista/aws/subnet"
  subnet_zones = {
     "105.2.0.0/24" = lookup( module.globals.availability_zone[module.Leaf5Vpc.region], "zone1", "" )
     "105.2.1.0/24" = lookup( module.globals.availability_zone[module.Leaf5Vpc.region], "zone1", "" )
     "105.2.2.0/24" = lookup( module.globals.availability_zone[module.Leaf5Vpc.region], "zone2", "" )
     "105.2.3.0/24" = lookup( module.globals.availability_zone[module.Leaf5Vpc.region], "zone2", "" )
  }
  subnet_names = {
     "105.2.0.0/24" = "${module.globals.topology}-Leaf5Subnet0"
     "105.2.1.0/24" = "${module.globals.topology}-Leaf5Subnet1"
     "105.2.2.0/24" = "${module.globals.topology}-Leaf5Subnet2"
     "105.2.3.0/24" = "${module.globals.topology}-Leaf5Subnet3"
   }
  vpc_id = module.Leaf5Vpc.vpc_id[0]
  topology_name = module.Leaf5Vpc.topology_name
  region = module.Leaf5Vpc.region
}

module "Leaf5CloudEOS1" {
  source = "../../../module/arista/aws/cloudEOS"
  role = "CloudLeaf"
  topology_name = module.Leaf5Vpc.topology_name
  cloudeos_ami = module.globals.eos_amis[module.Leaf5Vpc.region]
  keypair_name = module.globals.keypair_name[module.Leaf5Vpc.region]
  vpc_info = module.Leaf5Vpc.vpc_info
  intf_names = [
    "${module.globals.topology}-Leaf5CloudEOS1Intf0",
    "${module.globals.topology}-Leaf5CloudEOS1Intf1"
  ]
  interface_types = {
    "${module.globals.topology}-Leaf5CloudEOS1Intf0" = "internal"
    "${module.globals.topology}-Leaf5CloudEOS1Intf1" = "private"
  }
  subnetids  = {
      "${module.globals.topology}-Leaf5CloudEOS1Intf0" = module.Leaf5Subnet.vpc_subnets[0]
      "${module.globals.topology}-Leaf5CloudEOS1Intf1" = module.Leaf5Subnet.vpc_subnets[1]
  }
  private_ips = {"0": ["105.2.0.101"], "1": ["105.2.1.101"]}
  availability_zone = lookup( module.globals.availability_zone[module.Leaf5Vpc.region], "zone1", "" )
  region            = module.Leaf5Vpc.region
  tags = {
         "Name" = "${module.globals.topology}-Leaf5CloudEOS1"
         "Cnps" = "prod"
  }
  primary = true
  filename = "../../../userdata/eos_ipsec_config.tpl"
}

module "Leaf5CloudEOS2" {
  source = "../../../module/arista/aws/cloudEOS"
  role = "CloudLeaf"
  topology_name = module.Leaf5Vpc.topology_name
  cloudeos_ami = module.globals.eos_amis[module.Leaf5Vpc.region]
  keypair_name = module.globals.keypair_name[module.Leaf5Vpc.region]
  vpc_info = module.Leaf5Vpc.vpc_info
  intf_names = [
    "${module.globals.topology}-Leaf5CloudEOS2Intf0",
    "${module.globals.topology}-Leaf5CloudEOS2Intf1"
  ]
  interface_types = {
    "${module.globals.topology}-Leaf5CloudEOS2Intf0" = "internal"
    "${module.globals.topology}-Leaf5CloudEOS2Intf1" = "private"
  }
  subnetids  = {
      "${module.globals.topology}-Leaf5CloudEOS2Intf0" = module.Leaf5Subnet.vpc_subnets[2]
      "${module.globals.topology}-Leaf5CloudEOS2Intf1" = module.Leaf5Subnet.vpc_subnets[3]
  }
  private_ips = {"0": ["105.2.2.101"], "1": ["105.2.3.101"]}
  availability_zone = lookup( module.globals.availability_zone[module.Leaf5Vpc.region], "zone2", "" )
  region            = module.Leaf5Vpc.region
  tags = {
         "Name" = "${module.globals.topology}-Leaf5CloudEOS2"
         "Cnps" = "prod"
  }
  internal_route_table_id = module.Leaf5CloudEOS1.route_table_internal
  filename = "../../../userdata/eos_ipsec_config.tpl"
}

//Leaf6
module "Leaf6Vpc" {
  source         = "../../../module/arista/aws/vpc"
  topology_name  = module.globals.topology
  clos_name      = "${module.globals.topology}-clos"
  role           = "CloudLeaf"
  cidr_block     = ["106.2.0.0/16"]
  tags = {
    Name = "${module.globals.topology}-Leaf6Vpc"
    Cnps = "prod"
  }
  region = module.globals.aws_regions["region2"]
}

module "Leaf6Subnet" {
  source = "../../../module/arista/aws/subnet"
  subnet_zones = {
     "106.2.0.0/24" = lookup( module.globals.availability_zone[module.Leaf6Vpc.region], "zone1", "" )
     "106.2.1.0/24" = lookup( module.globals.availability_zone[module.Leaf6Vpc.region], "zone1", "" )
     "106.2.2.0/24" = lookup( module.globals.availability_zone[module.Leaf6Vpc.region], "zone2", "" )
     "106.2.3.0/24" = lookup( module.globals.availability_zone[module.Leaf6Vpc.region], "zone2", "" )
  }
  subnet_names = {
     "106.2.0.0/24" = "${module.globals.topology}-Leaf6Subnet0"
     "106.2.1.0/24" = "${module.globals.topology}-Leaf6Subnet1"
     "106.2.2.0/24" = "${module.globals.topology}-Leaf6Subnet2"
     "106.2.3.0/24" = "${module.globals.topology}-Leaf6Subnet3"
   }
  vpc_id = module.Leaf6Vpc.vpc_id[0]
  topology_name = module.Leaf6Vpc.topology_name
  region = module.Leaf6Vpc.region
}

module "Leaf6CloudEOS1" {
  source = "../../../module/arista/aws/cloudEOS"
  role = "CloudLeaf"
  topology_name = module.Leaf6Vpc.topology_name
  cloudeos_ami = module.globals.eos_amis[module.Leaf6Vpc.region]
  keypair_name = module.globals.keypair_name[module.Leaf6Vpc.region]
  vpc_info = module.Leaf6Vpc.vpc_info
  intf_names = [
    "${module.globals.topology}-Leaf6CloudEOS1Intf0",
    "${module.globals.topology}-Leaf6CloudEOS1Intf1"
  ]
  interface_types = {
    "${module.globals.topology}-Leaf6CloudEOS1Intf0" = "internal"
    "${module.globals.topology}-Leaf6CloudEOS1Intf1" = "private"
  }
  subnetids  = {
      "${module.globals.topology}-Leaf6CloudEOS1Intf0" = module.Leaf6Subnet.vpc_subnets[0]
      "${module.globals.topology}-Leaf6CloudEOS1Intf1" = module.Leaf6Subnet.vpc_subnets[1]
  }
  private_ips = {"0": ["106.2.0.101"], "1": ["106.2.1.101"]}
  availability_zone = lookup( module.globals.availability_zone[module.Leaf6Vpc.region], "zone1", "" )
  region            = module.Leaf6Vpc.region
  tags = {
         "Name" = "${module.globals.topology}-Leaf6CloudEOS1"
         "Cnps" = "prod"
  }
  primary = true
  filename = "../../../userdata/eos_ipsec_config.tpl"
}

module "Leaf6CloudEOS2" {
  source = "../../../module/arista/aws/cloudEOS"
  role = "CloudLeaf"
  topology_name = module.Leaf6Vpc.topology_name
  cloudeos_ami = module.globals.eos_amis[module.Leaf6Vpc.region]
  keypair_name = module.globals.keypair_name[module.Leaf6Vpc.region]
  vpc_info = module.Leaf6Vpc.vpc_info
  intf_names = [
    "${module.globals.topology}-Leaf6CloudEOS2Intf0",
    "${module.globals.topology}-Leaf6CloudEOS2Intf1"
  ]
  interface_types = {
    "${module.globals.topology}-Leaf6CloudEOS2Intf0" = "internal"
    "${module.globals.topology}-Leaf6CloudEOS2Intf1" = "private"
  }
  subnetids  = {
      "${module.globals.topology}-Leaf6CloudEOS2Intf0" = module.Leaf6Subnet.vpc_subnets[2]
      "${module.globals.topology}-Leaf6CloudEOS2Intf1" = module.Leaf6Subnet.vpc_subnets[3]
  }
  private_ips = {"0": ["106.2.2.101"], "1": ["106.2.3.101"]}
  availability_zone = lookup( module.globals.availability_zone[module.Leaf6Vpc.region], "zone2", "" )
  region            = module.Leaf6Vpc.region
  tags = {
         "Name" = "${module.globals.topology}-Leaf6CloudEOS2"
         "Cnps" = "prod"
  }
  internal_route_table_id = module.Leaf6CloudEOS1.route_table_internal
  filename = "../../../userdata/eos_ipsec_config.tpl"
}
//Leaf7
module "Leaf7Vpc" {
  source         = "../../../module/arista/aws/vpc"
  topology_name  = module.globals.topology
  clos_name      = "${module.globals.topology}-clos"
  role           = "CloudLeaf"
  cidr_block     = ["107.2.0.0/16"]
  tags = {
    Name = "${module.globals.topology}-Leaf7Vpc"
    Cnps = "prod"
  }
  region = module.globals.aws_regions["region2"]
}

module "Leaf7Subnet" {
  source = "../../../module/arista/aws/subnet"
  subnet_zones = {
     "107.2.0.0/24" = lookup( module.globals.availability_zone[module.Leaf7Vpc.region], "zone1", "" )
     "107.2.1.0/24" = lookup( module.globals.availability_zone[module.Leaf7Vpc.region], "zone1", "" )
     "107.2.2.0/24" = lookup( module.globals.availability_zone[module.Leaf7Vpc.region], "zone2", "" )
     "107.2.3.0/24" = lookup( module.globals.availability_zone[module.Leaf7Vpc.region], "zone2", "" )
  }
  subnet_names = {
     "107.2.0.0/24" = "${module.globals.topology}-Leaf7Subnet0"
     "107.2.1.0/24" = "${module.globals.topology}-Leaf7Subnet1"
     "107.2.2.0/24" = "${module.globals.topology}-Leaf7Subnet2"
     "107.2.3.0/24" = "${module.globals.topology}-Leaf7Subnet3"
   }
  vpc_id = module.Leaf7Vpc.vpc_id[0]
  topology_name = module.Leaf7Vpc.topology_name
  region = module.Leaf7Vpc.region
}

module "Leaf7CloudEOS1" {
  source = "../../../module/arista/aws/cloudEOS"
  role = "CloudLeaf"
  topology_name = module.Leaf7Vpc.topology_name
  cloudeos_ami = module.globals.eos_amis[module.Leaf7Vpc.region]
  keypair_name = module.globals.keypair_name[module.Leaf7Vpc.region]
  vpc_info = module.Leaf7Vpc.vpc_info
  intf_names = [
    "${module.globals.topology}-Leaf7CloudEOS1Intf0",
    "${module.globals.topology}-Leaf7CloudEOS1Intf1"
  ]
  interface_types = {
    "${module.globals.topology}-Leaf7CloudEOS1Intf0" = "internal"
    "${module.globals.topology}-Leaf7CloudEOS1Intf1" = "private"
  }
  subnetids  = {
      "${module.globals.topology}-Leaf7CloudEOS1Intf0" = module.Leaf7Subnet.vpc_subnets[0]
      "${module.globals.topology}-Leaf7CloudEOS1Intf1" = module.Leaf7Subnet.vpc_subnets[1]
  }
  private_ips = {"0": ["107.2.0.101"], "1": ["107.2.1.101"]}
  availability_zone = lookup( module.globals.availability_zone[module.Leaf7Vpc.region], "zone1", "" )
  region            = module.Leaf7Vpc.region
  tags = {
         "Name" = "${module.globals.topology}-Leaf7CloudEOS1"
         "Cnps" = "prod"
  }
  primary = true
  filename = "../../../userdata/eos_ipsec_config.tpl"
}

module "Leaf7CloudEOS2" {
  source = "../../../module/arista/aws/cloudEOS"
  role = "CloudLeaf"
  topology_name = module.Leaf7Vpc.topology_name
  cloudeos_ami = module.globals.eos_amis[module.Leaf7Vpc.region]
  keypair_name = module.globals.keypair_name[module.Leaf7Vpc.region]
  vpc_info = module.Leaf7Vpc.vpc_info
  intf_names = [
    "${module.globals.topology}-Leaf7CloudEOS2Intf0",
    "${module.globals.topology}-Leaf7CloudEOS2Intf1"
  ]
  interface_types = {
    "${module.globals.topology}-Leaf7CloudEOS2Intf0" = "internal"
    "${module.globals.topology}-Leaf7CloudEOS2Intf1" = "private"
  }
  subnetids  = {
      "${module.globals.topology}-Leaf7CloudEOS2Intf0" = module.Leaf7Subnet.vpc_subnets[2]
      "${module.globals.topology}-Leaf7CloudEOS2Intf1" = module.Leaf7Subnet.vpc_subnets[3]
  }
  private_ips = {"0": ["107.2.2.101"], "1": ["107.2.3.101"]}
  availability_zone = lookup( module.globals.availability_zone[module.Leaf7Vpc.region], "zone2", "" )
  region            = module.Leaf7Vpc.region
  tags = {
         "Name" = "${module.globals.topology}-Leaf7CloudEOS2"
         "Cnps" = "prod"
  }
  internal_route_table_id = module.Leaf7CloudEOS1.route_table_internal
  filename = "../../../userdata/eos_ipsec_config.tpl"
}
//Leaf8
module "Leaf8Vpc" {
  source         = "../../../module/arista/aws/vpc"
  topology_name  = module.globals.topology
  clos_name      = "${module.globals.topology}-clos"
  role           = "CloudLeaf"
  cidr_block     = ["108.2.0.0/16"]
  tags = {
    Name = "${module.globals.topology}-Leaf8Vpc"
    Cnps = "prod"
  }
  region = module.globals.aws_regions["region2"]
}

module "Leaf8Subnet" {
  source = "../../../module/arista/aws/subnet"
  subnet_zones = {
     "108.2.0.0/24" = lookup( module.globals.availability_zone[module.Leaf8Vpc.region], "zone1", "" )
     "108.2.1.0/24" = lookup( module.globals.availability_zone[module.Leaf8Vpc.region], "zone1", "" )
     "108.2.2.0/24" = lookup( module.globals.availability_zone[module.Leaf8Vpc.region], "zone2", "" )
     "108.2.3.0/24" = lookup( module.globals.availability_zone[module.Leaf8Vpc.region], "zone2", "" )
  }
  subnet_names = {
     "108.2.0.0/24" = "${module.globals.topology}-Leaf8Subnet0"
     "108.2.1.0/24" = "${module.globals.topology}-Leaf8Subnet1"
     "108.2.2.0/24" = "${module.globals.topology}-Leaf8Subnet2"
     "108.2.3.0/24" = "${module.globals.topology}-Leaf8Subnet3"
   }
  vpc_id = module.Leaf8Vpc.vpc_id[0]
  topology_name = module.Leaf8Vpc.topology_name
  region = module.Leaf8Vpc.region
}

module "Leaf8CloudEOS1" {
  source = "../../../module/arista/aws/cloudEOS"
  role = "CloudLeaf"
  topology_name = module.Leaf8Vpc.topology_name
  cloudeos_ami = module.globals.eos_amis[module.Leaf8Vpc.region]
  keypair_name = module.globals.keypair_name[module.Leaf8Vpc.region]
  vpc_info = module.Leaf8Vpc.vpc_info
  intf_names = [
    "${module.globals.topology}-Leaf8CloudEOS1Intf0",
    "${module.globals.topology}-Leaf8CloudEOS1Intf1"
  ]
  interface_types = {
    "${module.globals.topology}-Leaf8CloudEOS1Intf0" = "internal"
    "${module.globals.topology}-Leaf8CloudEOS1Intf1" = "private"
  }
  subnetids  = {
      "${module.globals.topology}-Leaf8CloudEOS1Intf0" = module.Leaf8Subnet.vpc_subnets[0]
      "${module.globals.topology}-Leaf8CloudEOS1Intf1" = module.Leaf8Subnet.vpc_subnets[1]
  }
  private_ips = {"0": ["108.2.0.101"], "1": ["108.2.1.101"]}
  availability_zone = lookup( module.globals.availability_zone[module.Leaf8Vpc.region], "zone1", "" )
  region            = module.Leaf8Vpc.region
  tags = {
         "Name" = "${module.globals.topology}-Leaf8CloudEOS1"
         "Cnps" = "prod"
  }
  primary = true
  filename = "../../../userdata/eos_ipsec_config.tpl"
}

module "Leaf8CloudEOS2" {
  source = "../../../module/arista/aws/cloudEOS"
  role = "CloudLeaf"
  topology_name = module.Leaf8Vpc.topology_name
  cloudeos_ami = module.globals.eos_amis[module.Leaf8Vpc.region]
  keypair_name = module.globals.keypair_name[module.Leaf8Vpc.region]
  vpc_info = module.Leaf8Vpc.vpc_info
  intf_names = [
    "${module.globals.topology}-Leaf8CloudEOS2Intf0",
    "${module.globals.topology}-Leaf8CloudEOS2Intf1"
  ]
  interface_types = {
    "${module.globals.topology}-Leaf8CloudEOS2Intf0" = "internal"
    "${module.globals.topology}-Leaf8CloudEOS2Intf1" = "private"
  }
  subnetids  = {
      "${module.globals.topology}-Leaf8CloudEOS2Intf0" = module.Leaf8Subnet.vpc_subnets[2]
      "${module.globals.topology}-Leaf8CloudEOS2Intf1" = module.Leaf8Subnet.vpc_subnets[3]
  }
  private_ips = {"0": ["108.2.2.101"], "1": ["108.2.3.101"]}
  availability_zone = lookup( module.globals.availability_zone[module.Leaf8Vpc.region], "zone2", "" )
  region            = module.Leaf8Vpc.region
  tags = {
         "Name" = "${module.globals.topology}-Leaf8CloudEOS2"
         "Cnps" = "prod"
  }
  internal_route_table_id = module.Leaf8CloudEOS1.route_table_internal
  filename = "../../../userdata/eos_ipsec_config.tpl"
}
//Leaf9
module "Leaf9Vpc" {
  source         = "../../../module/arista/aws/vpc"
  topology_name  = module.globals.topology
  clos_name      = "${module.globals.topology}-clos"
  role           = "CloudLeaf"
  cidr_block     = ["109.2.0.0/16"]
  tags = {
    Name = "${module.globals.topology}-Leaf9Vpc"
    Cnps = "prod"
  }
  region = module.globals.aws_regions["region2"]
}

module "Leaf9Subnet" {
  source = "../../../module/arista/aws/subnet"
  subnet_zones = {
     "109.2.0.0/24" = lookup( module.globals.availability_zone[module.Leaf9Vpc.region], "zone1", "" )
     "109.2.1.0/24" = lookup( module.globals.availability_zone[module.Leaf9Vpc.region], "zone1", "" )
     "109.2.2.0/24" = lookup( module.globals.availability_zone[module.Leaf9Vpc.region], "zone2", "" )
     "109.2.3.0/24" = lookup( module.globals.availability_zone[module.Leaf9Vpc.region], "zone2", "" )
  }
  subnet_names = {
     "109.2.0.0/24" = "${module.globals.topology}-Leaf9Subnet0"
     "109.2.1.0/24" = "${module.globals.topology}-Leaf9Subnet1"
     "109.2.2.0/24" = "${module.globals.topology}-Leaf9Subnet2"
     "109.2.3.0/24" = "${module.globals.topology}-Leaf9Subnet3"
   }
  vpc_id = module.Leaf9Vpc.vpc_id[0]
  topology_name = module.Leaf9Vpc.topology_name
  region = module.Leaf9Vpc.region
}

module "Leaf9CloudEOS1" {
  source = "../../../module/arista/aws/cloudEOS"
  role = "CloudLeaf"
  topology_name = module.Leaf9Vpc.topology_name
  cloudeos_ami = module.globals.eos_amis[module.Leaf9Vpc.region]
  keypair_name = module.globals.keypair_name[module.Leaf9Vpc.region]
  vpc_info = module.Leaf9Vpc.vpc_info
  intf_names = [
    "${module.globals.topology}-Leaf9CloudEOS1Intf0",
    "${module.globals.topology}-Leaf9CloudEOS1Intf1"
  ]
  interface_types = {
    "${module.globals.topology}-Leaf9CloudEOS1Intf0" = "internal"
    "${module.globals.topology}-Leaf9CloudEOS1Intf1" = "private"
  }
  subnetids  = {
      "${module.globals.topology}-Leaf9CloudEOS1Intf0" = module.Leaf9Subnet.vpc_subnets[0]
      "${module.globals.topology}-Leaf9CloudEOS1Intf1" = module.Leaf9Subnet.vpc_subnets[1]
  }
  private_ips = {"0": ["109.2.0.101"], "1": ["109.2.1.101"]}
  availability_zone = lookup( module.globals.availability_zone[module.Leaf9Vpc.region], "zone1", "" )
  region            = module.Leaf9Vpc.region
  tags = {
         "Name" = "${module.globals.topology}-Leaf9CloudEOS1"
         "Cnps" = "prod"
  }
  primary = true
  filename = "../../../userdata/eos_ipsec_config.tpl"
}

module "Leaf9CloudEOS2" {
  source = "../../../module/arista/aws/cloudEOS"
  role = "CloudLeaf"
  topology_name = module.Leaf9Vpc.topology_name
  cloudeos_ami = module.globals.eos_amis[module.Leaf9Vpc.region]
  keypair_name = module.globals.keypair_name[module.Leaf9Vpc.region]
  vpc_info = module.Leaf9Vpc.vpc_info
  intf_names = [
    "${module.globals.topology}-Leaf9CloudEOS2Intf0",
    "${module.globals.topology}-Leaf9CloudEOS2Intf1"
  ]
  interface_types = {
    "${module.globals.topology}-Leaf9CloudEOS2Intf0" = "internal"
    "${module.globals.topology}-Leaf9CloudEOS2Intf1" = "private"
  }
  subnetids  = {
      "${module.globals.topology}-Leaf9CloudEOS2Intf0" = module.Leaf9Subnet.vpc_subnets[2]
      "${module.globals.topology}-Leaf9CloudEOS2Intf1" = module.Leaf9Subnet.vpc_subnets[3]
  }
  private_ips = {"0": ["109.2.2.101"], "1": ["109.2.3.101"]}
  availability_zone = lookup( module.globals.availability_zone[module.Leaf9Vpc.region], "zone2", "" )
  region            = module.Leaf9Vpc.region
  tags = {
         "Name" = "${module.globals.topology}-Leaf9CloudEOS2"
         "Cnps" = "prod"
  }
  internal_route_table_id = module.Leaf9CloudEOS1.route_table_internal
  filename = "../../../userdata/eos_ipsec_config.tpl"
}
*/
