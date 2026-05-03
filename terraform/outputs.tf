output "ecr_repository_url" {
  description = "ECR repository URL — use this to tag and push your Docker image"
  value       = module.ecr.repository_url
}

output "alb_dns_name" {
  description = "ALB DNS name — access the app at http://<alb_dns_name>"
  value       = module.alb.alb_dns_name
}
