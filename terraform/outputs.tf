output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.asg.asg_name
}

output "launch_template_id" {
  description = "ID of the EC2 Launch Template"
  value       = module.asg.launch_template_id
}

output "asg_instance_ids" {
  description = "EC2 instance IDs currently running in the ASG"
  value       = module.asg.instance_ids
}

output "ecr_repository_url" {
  description = "ECR repository URL — use this to tag and push your Docker image"
  value       = module.ecr.repository_url
}

output "alb_dns_name" {
  description = "ALB DNS name — access the app at http://<alb_dns_name>"
  value       = module.alb.alb_dns_name
}

data "external" "ecs_task_public_ip" {
  depends_on = [module.ecs]

  program = ["bash", "-c", <<-EOT
    TASK_ARN=$(aws ecs list-tasks \
      --cluster "${module.ecs.cluster_name}" \
      --service-name "${module.ecs.service_name}" \
      --region us-east-1 \
      --profile admin \
      --query 'taskArns[0]' \
      --output text 2>/dev/null)
    if [ -z "$TASK_ARN" ] || [ "$TASK_ARN" = "None" ]; then
      printf '{"public_ip":"(no running task found)"}'
      exit 0
    fi
    ENI=$(aws ecs describe-tasks \
      --cluster "${module.ecs.cluster_name}" \
      --tasks "$TASK_ARN" \
      --region us-east-1 \
      --profile admin \
      --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value | [0]' \
      --output text 2>/dev/null)
    if [ -z "$ENI" ] || [ "$ENI" = "None" ]; then
      printf '{"public_ip":"(task starting — no ENI yet)"}'
      exit 0
    fi
    IP=$(aws ec2 describe-network-interfaces \
      --network-interface-ids "$ENI" \
      --region us-east-1 \
      --profile admin \
      --query 'NetworkInterfaces[0].Association.PublicIp' \
      --output text 2>/dev/null)
    if [ -z "$IP" ] || [ "$IP" = "None" ]; then
      printf '{"public_ip":"(no public IP assigned yet)"}'
      exit 0
    fi
    printf '{"public_ip":"%s"}' "$IP"
  EOT
  ]
}

output "ecs_task_public_ip" {
  description = "Public IP of the running ECS Fargate task"
  value       = data.external.ecs_task_public_ip.result["public_ip"]
}
