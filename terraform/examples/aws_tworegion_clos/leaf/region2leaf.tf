// Copyright (c) 2020 Arista Networks, Inc.
// Use of this source code is governed by the Apache License 2.0
// that can be found in the LICENSE file.
//=================Region2 Leaf1 CloudEOS1===============================
module "Region2Leaf1Vpc" {
  source        = "../../../module/cloudeos/aws/vpc"
  topology_name = var.topology
  clos_name     = "${var.topology}-clos"
  role          = "CloudLeaf"
  cidr_block    = ["101.2.0.0/16"]
  tags = {
    Name = "${var.topology}-Region2Leaf1Vpc"
    Cnps = "dev"
  }
  region = var.aws_regions["region2"]
}

module "Region2Leaf1Subnet" {
  source = "../../../module/cloudeos/aws/subnet"
  subnet_zones = {
    "101.2.0.0/24" = var.availability_zone[module.Region2Leaf1Vpc.region]["zone1"]
    "101.2.1.0/24" = var.availability_zone[module.Region2Leaf1Vpc.region]["zone1"]
  }
  subnet_names = {
    "101.2.0.0/24" = "${var.topology}-Region2Leaf1Subnet0"
    "101.2.1.0/24" = "${var.topology}-Region2Leaf1Subnet1"
  }
  vpc_id        = module.Region2Leaf1Vpc.vpc_id[0]
  topology_name = module.Region2Leaf1Vpc.topology_name
  region        = module.Region2Leaf1Vpc.region
}

module "Region2Leaf1CloudEOS1" {
  source        = "../../../module/cloudeos/aws/router"
  role          = "CloudLeaf"
  topology_name = module.Region2Leaf1Vpc.topology_name
  cloudeos_ami  = var.eos_amis[module.Region2Leaf1Vpc.region]
  keypair_name  = var.keypair_name[module.Region2Leaf1Vpc.region]
  vpc_info      = module.Region2Leaf1Vpc.vpc_info
  intf_names = [
    "${var.topology}-Region2Leaf1CloudEOS1Intf0",
    "${var.topology}-Region2Leaf1CloudEOS1Intf1"
  ]
  interface_types = {
    "${var.topology}-Region2Leaf1CloudEOS1Intf0" = "internal"
    "${var.topology}-Region2Leaf1CloudEOS1Intf1" = "private"
  }
  subnetids = {
    "${var.topology}-Region2Leaf1CloudEOS1Intf0" = module.Region2Leaf1Subnet.vpc_subnets[0]
    "${var.topology}-Region2Leaf1CloudEOS1Intf1" = module.Region2Leaf1Subnet.vpc_subnets[1]
  }
  private_ips       = { "0" : ["101.2.0.101"], "1" : ["101.2.1.101"] }
  availability_zone = var.availability_zone[module.Region2Leaf1Vpc.region]["zone1"]
  region            = module.Region2Leaf1Vpc.region
  tags = {
    "Name" = "${var.topology}-Region2Leaf1CloudEOS1"
    "Cnps" = "dev"
  }
  primary       = true
  filename      = "../../../userdata/eos_ipsec_config.tpl"
  instance_type = var.instance_type["leaf"]
}

module "Region2Leaf1host1" {
  region        = var.aws_regions["region2"]
  source        = "../../../module/cloudeos/aws/host"
  ami           = var.host_amis[module.Region2Leaf1Vpc.region]
  instance_type = "c5.xlarge"
  keypair_name  = var.keypair_name[module.Region2Leaf1Vpc.region]
  subnet_id     = module.Region2Leaf1Subnet.vpc_subnets[1]
  private_ips   = ["101.2.1.102"]
  tags = {
    "Name" = "${var.topology}-Region2Leaf1host"
  }
}

//=================Region2 Leaf2 CloudEOS1===============================
module "Region2Leaf2Vpc" {
  source        = "../../../module/cloudeos/aws/vpc"
  topology_name = var.topology
  clos_name     = "${var.topology}-clos"
  role          = "CloudLeaf"
  cidr_block    = ["102.2.0.0/16"]
  tags = {
    Name = "${var.topology}-Region2Leaf2Vpc"
    Cnps = "prod"
  }
  region = var.aws_regions["region2"]
}

module "Region2Leaf2Subnet" {
  source = "../../../module/cloudeos/aws/subnet"
  subnet_zones = {
    "102.2.0.0/24" = var.availability_zone[module.Region2Leaf2Vpc.region]["zone1"]
    "102.2.1.0/24" = var.availability_zone[module.Region2Leaf2Vpc.region]["zone1"]
  }
  subnet_names = {
    "102.2.0.0/24" = "${var.topology}-Region2Leaf2Subnet0"
    "102.2.1.0/24" = "${var.topology}-Region2Leaf2Subnet1"
  }
  vpc_id        = module.Region2Leaf2Vpc.vpc_id[0]
  topology_name = module.Region2Leaf2Vpc.topology_name
  region        = module.Region2Leaf2Vpc.region
}

module "Region2Leaf2CloudEOS1" {
  source        = "../../../module/cloudeos/aws/router"
  role          = "CloudLeaf"
  topology_name = module.Region2Leaf2Vpc.topology_name
  cloudeos_ami  = var.eos_amis[module.Region2Leaf2Vpc.region]
  keypair_name  = var.keypair_name[module.Region2Leaf2Vpc.region]
  vpc_info      = module.Region2Leaf2Vpc.vpc_info
  intf_names = [
    "${var.topology}-Region2Leaf2CloudEOS1Intf0",
    "${var.topology}-Region2Leaf2CloudEOS1Intf1"
  ]
  interface_types = {
    "${var.topology}-Region2Leaf2CloudEOS1Intf0" = "internal"
    "${var.topology}-Region2Leaf2CloudEOS1Intf1" = "private"
  }
  subnetids = {
    "${var.topology}-Region2Leaf2CloudEOS1Intf0" = module.Region2Leaf2Subnet.vpc_subnets[0]
    "${var.topology}-Region2Leaf2CloudEOS1Intf1" = module.Region2Leaf2Subnet.vpc_subnets[1]
  }
  private_ips       = { "0" : ["102.2.0.101"], "1" : ["102.2.1.101"] }
  availability_zone = var.availability_zone[module.Region2Leaf2Vpc.region]["zone1"]
  region            = module.Region2Leaf2Vpc.region
  tags = {
    "Name" = "${var.topology}-Region2Leaf2CloudEOS1"
    "Cnps" = "prod"
  }
  primary       = true
  filename      = "../../../userdata/eos_ipsec_config.tpl"
  instance_type = var.instance_type["leaf"]
}

module "Region2Leaf2host1" {
  region        = var.aws_regions["region2"]
  source        = "../../../module/cloudeos/aws/host"
  ami           = var.host_amis[module.Region2Leaf2Vpc.region]
  instance_type = "c5.xlarge"
  keypair_name  = var.keypair_name[module.Region2Leaf2Vpc.region]
  subnet_id     = module.Region2Leaf2Subnet.vpc_subnets[1]
  private_ips   = ["102.2.1.102"]
  tags = {
    "Name" = "${var.topology}-Region2Leaf2host"
  }
}
