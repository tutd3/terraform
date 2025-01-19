provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_count = 3  # Set to 3 Availability Zones
  az_names = slice(data.aws_availability_zones.available.names, 0, local.az_count)
  az_ids   = slice(data.aws_availability_zones.available.names, 0, local.az_count)
  cidr_prefix = join(".", slice(split(".", var.cidr_block), 0, 2))
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block                    = var.cidr_block
  enable_dns_hostnames          = true
  assign_generated_ipv6_cidr_block = var.assign_ipv6

  tags = {
    "Name"        = var.vpc_name
    "project"     = var.project_tag
    "environment" = var.environment_tag
  }
}

# Create Public Subnets (3 Subnets for 3 AZs)
resource "aws_subnet" "public" {
  count                           = local.az_count
  availability_zone               = local.az_names[count.index]
  cidr_block                      = "${local.cidr_prefix}.${count.index * 4}.0/22"
  ipv6_cidr_block                 = var.assign_ipv6 ? cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, tonumber(count.index)) : null
  assign_ipv6_address_on_creation = var.assign_ipv6 ? true : false
  vpc_id                          = aws_vpc.main.id
  map_public_ip_on_launch         = true

  tags = {
    "Name"        = "${var.vpc_name}-public-${local.az_ids[count.index]}"
    "project"     = var.project_tag
    "environment" = var.environment_tag
    "access"      = "public"
  }
}

# Create Private Subnets (3 Subnets for 3 AZs)
resource "aws_subnet" "private" {
  count                   = local.az_count
  availability_zone       = local.az_names[count.index]
  cidr_block              = "${local.cidr_prefix}.${(local.az_count + count.index) * 4}.0/22"
  ipv6_cidr_block         = var.assign_ipv6 ? cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, tonumber(local.az_count + count.index)) : null
  assign_ipv6_address_on_creation = var.assign_ipv6 ? true : false
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = false

  tags = {
    "Name"        = "${var.vpc_name}-private-${local.az_ids[count.index]}"
    "project"     = var.project_tag
    "environment" = var.environment_tag
    "access"      = "private"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name"        = "${var.vpc_name}-igw"
    "project"     = var.project_tag
    "environment" = var.environment_tag
  }
}

# Create Elastic IP for NAT Gateway
resource "aws_eip" "main" {
  domain = "vpc"
  tags = {
    "Name"        = "${var.vpc_name}-eip"
    "project"     = var.project_tag
    "environment" = var.environment_tag
  }
}

# Create NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    "Name"        = "${var.vpc_name}-nat"
    "project"     = var.project_tag
    "environment" = var.environment_tag
  }
}

# Create Route Tables and Routes
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name"        = "${var.vpc_name}-public-rtb"
    "project"     = var.project_tag
    "environment" = var.environment_tag
  }
}

resource "aws_route" "public" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count          = local.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name"        = "${var.vpc_name}-private-rtb"
    "project"     = var.project_tag
    "environment" = var.environment_tag
  }
}

resource "aws_route" "private" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = aws_nat_gateway.main.id
}

resource "aws_route_table_association" "private" {
  count          = local.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Peering Connection Routes
resource "aws_route" "peering" {
  count                  = length(var.peering_connection_cidr_blocks) > 0 && var.enable_peering_connection ? length(var.peering_connection_cidr_blocks) : 0
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = element(var.peering_connection_cidr_blocks, count.index)
  vpc_peering_connection_id = element(var.vpc_peering_connection_ids, count.index)
}

resource "aws_route" "private_peering" {
  count                  = length(var.peering_connection_cidr_blocks) > 0 && var.enable_peering_connection ? length(var.peering_connection_cidr_blocks) : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = element(var.peering_connection_cidr_blocks, count.index)
  vpc_peering_connection_id = element(var.vpc_peering_connection_ids, count.index)
}

# Transit Gateway Routes
resource "aws_route" "transit_gateway" {
  count                  = length(var.transit_gateway_cidr_blocks) > 0 && var.enable_transit_gateway ? length(var.transit_gateway_cidr_blocks) : 0
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = element(var.transit_gateway_cidr_blocks, count.index)
  transit_gateway_id     = element(var.transit_gateway_ids, count.index)
}

resource "aws_route" "private_transit_gateway" {
  count                  = length(var.transit_gateway_cidr_blocks) > 0 && var.enable_transit_gateway ? length(var.transit_gateway_cidr_blocks) : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = element(var.transit_gateway_cidr_blocks, count.index)
  transit_gateway_id     = element(var.transit_gateway_ids, count.index)
}

# Virtual Private Gateway Routes
resource "aws_route" "virtual_private_gateway" {
  count                  = length(var.virtual_private_gateway_cidr_blocks) > 0 && var.enable_virtual_private_gateway ? length(var.virtual_private_gateway_cidr_blocks) : 0
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = element(var.virtual_private_gateway_cidr_blocks, count.index)
  gateway_id             = element(var.virtual_private_gateway_ids, count.index)
}

resource "aws_route" "private_virtual_private_gateway" {
  count                  = length(var.virtual_private_gateway_cidr_blocks) > 0 && var.enable_virtual_private_gateway ? length(var.virtual_private_gateway_cidr_blocks) : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = element(var.virtual_private_gateway_cidr_blocks, count.index)
  gateway_id             = element(var.virtual_private_gateway_ids, count.index)
}

