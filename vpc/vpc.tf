module "vpc" {
  source = "./module-3"

  region                         = "ap-southeast-1"
  cidr_block                     = "10.0.0.0/16"
  assign_ipv6                    = false
  vpc_name                       = "my-vpc"
  project_tag                    = "my-project"
  environment_tag                = "dev"

  # Enable Peering, Transit Gateway, and Virtual Private Gateway
  enable_peering_connection      = false
  enable_transit_gateway         = false
  enable_virtual_private_gateway = false

  # List of Peering Connection IDs
  vpc_peering_connection_ids     = ["pcx-12345678", "pcx-87654321"]

  # List of Transit Gateway IDs
  transit_gateway_ids            = ["tgw-12345678", "tgw-87654321"]

  # List of Virtual Private Gateway IDs
  virtual_private_gateway_ids    = ["vgw-12345678", "vgw-87654321"]

  # CIDR blocks for Peering Connection, Transit Gateway, and Virtual Private Gateway
  peering_connection_cidr_blocks = ["10.1.0.0/16", "10.2.0.0/16"]
  transit_gateway_cidr_blocks    = ["192.168.0.0/16", "192.169.0.0/16"]
  virtual_private_gateway_cidr_blocks = ["172.16.0.0/16"]
}
