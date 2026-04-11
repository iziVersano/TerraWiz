variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment tag"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_a_cidr" {
  description = "CIDR block for public subnet A (us-east-1a)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_b_cidr" {
  description = "CIDR block for public subnet B (us-east-1b)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "app_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000
}
