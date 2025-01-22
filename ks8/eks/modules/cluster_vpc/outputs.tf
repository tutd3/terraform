output "vpc_id" {
  description = "AWS VPC id created"
  value       = aws_vpc.main.id
}

output "all_subnet_ids" {
  description = "all vpc subnet ids (private and public)"
  value       = concat(aws_subnet.public.*.id, aws_subnet.private.*.id)
}

output "public_subnet_ids" {
  description = "vpc subnet ids public only"
  value       = aws_subnet.public.*.id
}

output "private_subnet_ids" {
  description = "vpc subnet ids private only"
  value       = aws_subnet.private.*.id
}

output "nat_eip" {
  description = "AWS NAT elastic IP"
  value       = aws_eip.main.public_ip
}
