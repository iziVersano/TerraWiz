output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (passed to ECS service)"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "security_group_id" {
  description = "ID of the app security group (passed to ECS service)"
  value       = aws_security_group.app.id
}
