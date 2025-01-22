################################################################################
# ECR resources
# - Registry
# - Lifecycle Policy (TODO)
################################################################################
module "project_ecr" {
  source   = "./modules/project_ecr"
  for_each = var.ecr_projects

  repository_name      = each.key
  image_tag_mutability = each.value.image_tag_mutability
  scan_on_push         = each.value.scan_on_push
}

################################################################################
# VPC Resources
# - VPC
# - Subnet
# - IGW
# - NAT
# - Route table
################################################################################
locals {
  blank_vpc_id = var.vpc_id == ""
}

module "cluster_vpc" {
  count        = local.blank_vpc_id ? 1 : 0
  source       = "./modules/cluster_vpc"
  cluster_name = var.cluster_name
  cidr_block   = var.new_vpc_cidr_block
}

################################################################################
# EKS Cluster (Control Plane)
################################################################################
locals {
  cluster_vpc_id              = local.blank_vpc_id ? module.cluster_vpc[0].vpc_id : var.vpc_id
  cluster_subnet_ids          = local.blank_vpc_id ? module.cluster_vpc[0].all_subnet_ids : var.cluster_subnet_ids
  cluster_public_subnet_ids   = local.blank_vpc_id ? module.cluster_vpc[0].public_subnet_ids : var.cluster_public_subnet_ids
  cluster_public_subnet_ids2  = local.blank_vpc_id ? module.cluster_vpc[0].public_subnet_ids2 : var.cluster_public_subnet_ids2
  cluster_public_subnet_ids3  = local.blank_vpc_id ? module.cluster_vpc[0].public_subnet_ids3 : var.cluster_public_subnet_ids3
  cluster_private_subnet_ids  = local.blank_vpc_id ? module.cluster_vpc[0].private_subnet_ids : var.cluster_private_subnet_ids
  cluster_private_subnet_ids2 = local.blank_vpc_id ? module.cluster_vpc[0].private_subnet_ids2 : var.cluster_private_subnet_ids2
  cluster_private_subnet_ids3 = local.blank_vpc_id ? module.cluster_vpc[0].private_subnet_ids3 : var.cluster_private_subnet_ids3
  cluster_vpc_nat_eip         = local.blank_vpc_id ? module.cluster_vpc[0].nat_eip : "use existing vpc"
}

# NOTES: by default using all subnet ids
# reference: https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
# in summary AWS, recommend to use public and private subnets so that Kubernetes can create public load balancers in the public subnets that load balance traffic to pods running on nodes that are in private subnets
module "cluster_control_plane" {
  source                  = "./modules/cluster_control_plane"
  aws_account_id          = var.aws_account_id
  cluster_name            = var.cluster_name
  k8s_version             = var.k8s_version
  public_access_cidrs     = var.cluster_public_access_cidrs
  endpoint_private_access = var.endpoint_private_access
  endpoint_public_access  = var.endpoint_public_access
  cluster_tags            = var.cluster_tags
  service_ipv4_cidr       = var.service_ipv4_cidr
  vpc_id                  = local.cluster_vpc_id
  subnet_ids              = local.cluster_subnet_ids
}

################################################################################
# EKS Cluster (Worker Nodes)
################################################################################
module "cluster_worker_nodes" {
  source                      = "./modules/cluster_worker_nodes"
  public_subnet_ids           = local.cluster_public_subnet_ids
  public_subnet_ids2          = local.cluster_public_subnet_ids2
  public_subnet_ids3          = local.cluster_public_subnet_ids3
  private_subnet_ids          = local.cluster_private_subnet_ids
  private_subnet_ids2         = local.cluster_private_subnet_ids2
  private_subnet_ids3         = local.cluster_private_subnet_ids3
  cluster_name                = var.cluster_name
  k8s_version                 = var.k8s_version
  worker_nodes                = var.worker_nodes
  cluster_addons              = var.cluster_addons
  cluster_addons_timeouts     = var.cluster_addons_timeouts
  cluster_tags                = var.cluster_tags
  use_custom_launch_template  = var.use_custom_launch_template
  launch_template_variable    = var.launch_template_variable

  depends_on = [
    module.cluster_control_plane
  ]
}