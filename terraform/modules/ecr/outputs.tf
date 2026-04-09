output "repository_url" {
  description = "Full ECR repository URL (used for docker push and ECS task definition)"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.this.name
}
