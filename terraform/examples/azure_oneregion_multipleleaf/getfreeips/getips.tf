data "external" "get_ip_availables" {
    program = ["bash", ".terraform/modules/get_ips/script/get_ip_availables.sh"]
    query = {
      subscription = "f1592ec1-9735-4a9b-b3c0-ef9854674431"
      resource_group = "amadeus_hub_rg"
      vnet_name = "amadeus_hub"
      subnet_name = var.subnet_names[count.index]
  }
  count = length(var.subnet_names)
}
