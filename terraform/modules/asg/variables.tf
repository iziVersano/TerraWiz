variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment tag"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the launch template"
  type        = string
  default     = "t3.micro"
}

variable "subnet_ids" {
  description = "List of subnet IDs the ASG can launch instances into"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID attached to each launched instance"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 1
}

variable "desired_capacity" {
  description = "Desired number of running instances"
  type        = number
  default     = 1
}
