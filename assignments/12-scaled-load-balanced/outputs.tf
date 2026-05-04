output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the two public subnets"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "alb_dns_name" {
  description = "ALB DNS name — open http://<alb_dns_name> in a browser"
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "ARN of the Target Group"
  value       = aws_lb_target_group.this.arn
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}

output "launch_template_id" {
  description = "ID of the EC2 Launch Template"
  value       = aws_launch_template.this.id
}

output "desired_capacity" {
  description = "Desired number of EC2 instances"
  value       = aws_autoscaling_group.this.desired_capacity
}

output "min_capacity" {
  description = "Minimum number of EC2 instances"
  value       = aws_autoscaling_group.this.min_size
}

output "max_capacity" {
  description = "Maximum number of EC2 instances"
  value       = aws_autoscaling_group.this.max_size
}
