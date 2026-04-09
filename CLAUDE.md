# TerraWiz — Project Memory

## Overview
TerraWiz is a learning project that deploys a Node.js hello-world server to AWS ECS Fargate using only Terraform. Nothing is created by clicking in the AWS Console. Every resource is code.

## Goal
Build a containerized Node.js app → push to AWS ECR → deploy on ECS Fargate → all via Terraform.

## Rules (non-negotiable)
- **Terraform only** for all AWS infrastructure. No `aws` CLI commands that create/modify resources.
- **No AWS Console** — if you can't do it in Terraform, we don't do it.
- **Git commits** after every phase, clean conventional commit messages.
- **No AI attribution** in commits. Commit messages read as my own work.

## AWS Configuration
- **Region:** `us-east-1` (US East — N. Virginia)
- **Naming convention:** `terrawiz-<resource>` (e.g., `terrawiz-cluster`, `terrawiz-ecr`)
- **Environment:** `dev` (single env for this project)

## Cost Warning — READ THIS
Fargate has **NO free tier**. Every hour a task runs costs money.

| Resource | Approx. Cost |
|---|---|
| Fargate (0.25 vCPU / 0.5 GB) | ~$0.01–$0.03/hr |
| NAT Gateway | ~$0.045/hr + data ($0.045/GB) |
| Public IPv4 address | ~$0.005/hr |

**When done reviewing: run `/destroy` to tear everything down.**

To destroy manually:
```bash
cd terraform
terraform destroy
```

## Phase Progress
- [ ] Phase 1 — Project setup and scaffolding
- [ ] Phase 2 — Node.js hello-world app
- [ ] Phase 3 — Multi-stage Dockerfile
- [ ] Phase 4 — Terraform ECR module
- [ ] Phase 5 — Build and push image to ECR
- [ ] Phase 6 — Terraform networking module (VPC, subnets, IGW, SG)
- [ ] Phase 7 — Terraform IAM module (task execution role)
- [ ] Phase 8 — Terraform ECS module (cluster, task def, service)
- [ ] Phase 9 — Verify and document

## Architecture (filled in as phases complete)
TBD — updated in Phase 9.
