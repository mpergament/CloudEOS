// Copyright (c) 2020 Arista Networks, Inc.
// Use of this source code is governed by the Apache License 2.0
// that can be found in the LICENSE file.
resource "cloudeos_router_status" "router" {
  count                        = var.topology_name != "" ? 1 : 0
  cloud_provider               = "aws"
  cv_container                 = var.cv_container
  cnps                         = lookup(var.tags, "Cnps", "")
  vpc_id                       = var.vpc_info[0][0]
  instance_id                  = aws_instance.cloudeosVm.id
  instance_type                = var.instance_type
  region                       = var.region
  tags                         = var.tags //tags should have the Name.
  availability_zone            = aws_instance.cloudeosVm.availability_zone
  primary_network_interface_id = aws_instance.cloudeosVm.primary_network_interface_id
  public_ip                    = length(aws_eip.eip.*.public_ip) > 0 ? aws_eip.eip.*.public_ip[0] : ""
  intf_name                    = var.intf_names
  intf_id                      = aws_network_interface.allIntfs.*.id
  intf_private_ip              = aws_network_interface.allIntfs.*.private_ip
  intf_subnet_id               = aws_network_interface.allIntfs.*.subnet_id
  intf_type                    = values(var.interface_types)
  ha_name                      = var.cloud_ha
  private_rt_table_ids         = aws_route_table.route_table_private.*.id
  internal_rt_table_ids        = aws_route_table.route_table_internal.*.id
  public_rt_table_ids          = aws_route_table.route_table_public.*.id
  tf_id                        = cloudeos_router_config.router[0].tf_id
  is_rr                        = var.is_rr
  routing_resource_info        = flatten([aws_route.wan_default_route.*.id, aws_route.lan_default_route.*.id, aws_route.internal_default_route.*.id, aws_route_table_association.route_map_public.*.id, aws_route_table_association.route_map_internal.*.id, aws_route_table_association.route_map_private.*.id, aws_network_interface_attachment.secondary_intf.*.id])
}
