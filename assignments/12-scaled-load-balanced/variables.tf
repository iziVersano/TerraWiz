variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "terrawiz-12"
}

variable "environment" {
  description = "Deployment environment tag"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.12.0.0/16"
}

variable "subnet_a_cidr" {
  description = "CIDR block for public subnet in us-east-1a"
  type        = string
  default     = "10.12.1.0/24"
}

variable "subnet_b_cidr" {
  description = "CIDR block for public subnet in us-east-1b"
  type        = string
  default     = "10.12.2.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for the launch template"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of EC2 instances in the ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of EC2 instances in the ASG"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances in the ASG"
  type        = number
  default     = 2
}
