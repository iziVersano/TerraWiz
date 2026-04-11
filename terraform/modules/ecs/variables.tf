variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment tag"
  type        = string
}

variable "ecr_repository_url" {
  description = "Full ECR repository URL for the container image"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution IAM role"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs to place the Fargate task in"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID to attach to the Fargate task"
  type        = string
}

variable "app_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000
}

variable "cpu" {
  description = "CPU units for the task (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory for the task in MB (512 = 0.5 GB)"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of tasks to keep running"
  type        = number
  default     = 1
}
