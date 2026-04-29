variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment tag"
  type        = string
}

variable "uploads_bucket_arn" {
  description = "ARN of the S3 uploads bucket — grants the ECS task write access"
  type        = string
}
