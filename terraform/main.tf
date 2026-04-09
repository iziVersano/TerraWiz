terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Modules will be wired in here as phases complete:
# Phase 4  — module "ecr"
# Phase 6  — module "networking"
# Phase 7  — module "iam"
# Phase 8  — module "ecs"
