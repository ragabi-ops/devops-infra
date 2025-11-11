output "vpc_id" {
  value       = aws_vpc.this.id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = values(aws_subnet.public)[*].id
  description = "Public subnet IDs"
}

output "private_subnet_ids" {
  value       = values(aws_subnet.private)[*].id
  description = "Private subnet IDs"
}

output "default_app_sg_id" {
  value       = aws_security_group.default_app.id
  description = "Default application security group"
}
