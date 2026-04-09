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

module "ecr" {
  source          = "./modules/ecr"
  repository_name = "${var.project_name}"
  project_name    = var.project_name
}

# Phase 6  — module "networking"
# Phase 7  — module "iam"
# Phase 8  — module "ecs"
