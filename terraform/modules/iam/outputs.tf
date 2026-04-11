output "execution_role_arn" {
  description = "ARN of the ECS task execution role (passed to the task definition)"
  value       = aws_iam_role.ecs_task_execution.arn
}
