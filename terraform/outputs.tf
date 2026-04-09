# Phase 8 will add the public IP / URL of the running Fargate service.

output "ecr_repository_url" {
  description = "ECR repository URL — use this to tag and push your Docker image"
  value       = module.ecr.repository_url
}
