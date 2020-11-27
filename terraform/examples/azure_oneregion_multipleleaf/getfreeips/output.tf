output "ip_availables" {
  value = [for iplist in  data.external.get_ip_availables: "${split(var.delimiter, iplist.result.data)}"]
}
