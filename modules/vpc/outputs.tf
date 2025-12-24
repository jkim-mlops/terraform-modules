output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs in the VPC"
  value       = [for s in aws_subnet.this : s.id if s.map_public_ip_on_launch]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs in the VPC"
  value       = [for s in aws_subnet.this : s.id if !s.map_public_ip_on_launch]
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}