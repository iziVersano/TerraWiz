variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment tag"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to create the ALB and target group in"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs to place the ALB in"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID to attach to the ALB"
  type        = string
}

variable "app_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000
}
