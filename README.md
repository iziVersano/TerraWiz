# TerraWiz

**Live app:** http://terrawiz-alb-\<id\>.us-east-1.elb.amazonaws.com/

A learning project that deploys a Node.js app to AWS ECS Fargate using only Terraform. No AWS Console. No clicking. Everything is code.

## Goal

Build a containerized Node.js app → push to AWS ECR → deploy on ECS Fargate → all via Terraform.

## Phases

### Phase 1 — Project Setup
Scaffolded the project structure, configured Claude Code, set up `.gitignore` and conventions.

### Phase 2 — Node.js App
Built a simple Express server with two endpoints:
- `GET /` — returns a JSON hello message and environment
- `GET /health` — returns `{ status: "ok" }` for health checks

### Phase 3 — Multi-Stage Dockerfile
Created a multi-stage Dockerfile with two targets:
- `dev` — includes nodemon for hot reloading during development
- `prod` — lean image, production dependencies only, runs with `node` directly

### Phase 4 — Terraform ECR Module
Wrote a Terraform module that provisions an AWS ECR repository to store the Docker image. Includes a lifecycle policy to keep only the last 5 images.

### Phase 5 — Build and Push Image to ECR
Wrote a bash script (`scripts/push-to-ecr.sh`) that builds the prod Docker image, authenticates to ECR, and pushes it.

### Phase 6 — Terraform Networking Module
Wrote a Terraform module that provisions the full network layer:
- VPC (`10.0.0.0/16`)
- Two public subnets across two Availability Zones (`us-east-1a`, `us-east-1b`)
- Internet Gateway + Route Table for outbound internet access
- Security Group allowing inbound traffic on port 3000

### Phase 7 — Terraform IAM Module
Wrote a Terraform module that creates the ECS Task Execution Role — the IAM role that allows ECS to pull the image from ECR and write logs to CloudWatch.

### Phase 8 — Terraform ECS Module
Wrote a Terraform module that provisions the full compute layer:
- ECS Cluster (`terrawiz-cluster`)
- CloudWatch Log Group for container logs
- Task Definition (0.25 vCPU / 0.5 GB RAM, pulls image from ECR)
- Fargate Service (keeps 1 task running inside the VPC we built)

### Phase 9 — Deploy and Verify
Ran `terraform apply` to create all 16 AWS resources. Pushed the Docker image to ECR. Verified the app is reachable at the Fargate task's public IP.

### Phase 10 — Application Load Balancer
Added an ALB in front of the Fargate service to provide a stable, DNS-based endpoint:
- Terraform ALB module (`aws_lb`, `aws_lb_listener`, `aws_lb_target_group`)
- Target group uses `ip` target type (required for Fargate awsvpc networking), health-checks `GET /health`
- HTTP listener on port 80 forwards to the target group
- ECS service registers tasks with the target group via `load_balancer` block
- Security group updated to allow inbound traffic on port 80
- `alb_dns_name` output exposes the stable endpoint after `terraform apply`

## Architecture

```
Docker Image → ECR
                ↓
         ECS pulls image (IAM role)
                ↓
         Fargate Task (0.25 vCPU / 0.5 GB)
                ↓
         ALB Target Group (port 3000, /health checks)
                ↓
         Application Load Balancer (port 80)
                ↓
         Public Subnet (VPC 10.0.0.0/16)
                ↓
         Internet Gateway
                ↓
         Public Internet → http://<alb-dns-name>
```

## Stack

| Layer | Technology |
|---|---|
| App | Node.js + Express |
| Container | Docker (multi-stage) |
| Registry | AWS ECR |
| Compute | AWS ECS Fargate |
| Networking | AWS VPC, Subnets, IGW, Security Group, ALB |
| Permissions | AWS IAM |
| Infrastructure | Terraform |

## Cost Warning

Fargate has no free tier. Tear down when not in use:

```bash
cd terraform && terraform destroy
```

## Test

This line was added to resolve issue #8.
