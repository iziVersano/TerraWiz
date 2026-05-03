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
  region  = var.aws_region
  profile = "admin"
}

module "ecr" {
  source          = "./modules/ecr"
  repository_name = var.project_name
  project_name    = var.project_name
}

module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  environment  = var.environment
}

module "iam" {
  source             = "./modules/iam"
  project_name       = var.project_name
  environment        = var.environment
  uploads_bucket_arn = module.s3.bucket_arn
}

module "s3" {
  source       = "./modules/s3"
  project_name = var.project_name
  environment  = var.environment
}

module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  subnet_ids        = module.networking.public_subnet_ids
  security_group_id = module.networking.security_group_id
}

module "ecs" {
  source = "./modules/ecs"

  project_name       = var.project_name
  environment        = var.environment
  ecr_repository_url = module.ecr.repository_url
  execution_role_arn = module.iam.execution_role_arn
  subnet_ids         = module.networking.public_subnet_ids
  security_group_id  = module.networking.security_group_id
  target_group_arn   = module.alb.target_group_arn
}
