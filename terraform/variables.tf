variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for all resources (e.g. terrawiz-cluster)"
  type        = string
  default     = "terrawiz"
}

variable "environment" {
  description = "Deployment environment tag"
  type        = string
  default     = "dev"
}
