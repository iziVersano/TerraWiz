output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}

output "launch_template_id" {
  description = "ID of the EC2 Launch Template"
  value       = aws_launch_template.this.id
}

output "launch_template_name" {
  description = "Name of the EC2 Launch Template"
  value       = aws_launch_template.this.name
}

output "instance_ids" {
  description = "IDs of EC2 instances currently running in the ASG"
  value       = data.aws_instances.asg_instances.ids
}
