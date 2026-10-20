output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

# Map AZ name -> subnet id, supaya consumer (mis. stack ec2) bisa pilih zona
# eksplisit (mis. "ap-southeast-3b") tanpa harus tahu urutan index.
output "public_subnets_by_az" {
  value = { for idx, s in aws_subnet.public : data.aws_availability_zones.available.names[idx] => s.id }
}

output "private_subnets_by_az" {
  value = { for idx, s in aws_subnet.private : data.aws_availability_zones.available.names[idx] => s.id }
}
