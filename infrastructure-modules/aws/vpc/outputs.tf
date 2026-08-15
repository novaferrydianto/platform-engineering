output "vpc_id" {
  description = "VPC identifier"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "private_subnet_ids" {
  description = "Private subnet identifiers, ordered by availability zone"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet identifiers, ordered by availability zone"
  value       = aws_subnet.public[*].id
}

output "nat_gateway_public_ips" {
  description = "NAT gateway public IPs — use these when allowlisting egress at a third party"
  value       = aws_eip.nat[*].public_ip
}

output "default_security_group_id" {
  description = "The intentionally empty default security group"
  value       = aws_default_security_group.this.id
}
