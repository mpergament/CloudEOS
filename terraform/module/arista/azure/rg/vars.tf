variable "vnet_name" {
  description = "Name of the vnet to create"
}

variable "rg_name" {
  description = "Default resource group name that the network will be created in."
}

variable "rg_location" {
  description = "The location/region where the core network will be created."
  default     = "westus"
}

variable "address_space" {
  description = "The address space that is used by the virtual network."
}

variable "tags" {
  description = "Tags for the vnet"
  type        = map(string)
  default     = {}
}

variable "nsg_name" {
  description = "nsg name"
  default     = ""
}

variable "peer_name" {
  default = "VNETPeering"
}

variable "role" {
  default = ""
}

variable "overlay_connection_type" {
  description = "Overlay connection type: dps/vxlan/dps"
  type        = string
  default     = "dps"
}

variable "peervpccidr" {
  default = ""
}

variable "peerrgname" {
  default = ""
}

variable "peervnetname" {
  default = ""
}
variable "topology_name" {
  default = ""
}
variable "availability_set" {
  default = false
}

variable "clos_name" {
  default = ""
}

variable "wan_name" {
  default = ""
}