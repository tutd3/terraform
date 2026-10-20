output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "public_subnets_by_az" {
  value = module.vpc.public_subnets_by_az
}

output "private_subnets_by_az" {
  value = module.vpc.private_subnets_by_az
}
