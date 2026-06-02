# ============================================================
# variables.tf
# Defines every input value used across all other .tf files.
# Nothing in AWS is created by this file — it is pure config.
# ============================================================

# ------------------------------------------------------------
# REGION
# ------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy everything into"
  type        = string
  default     = "eu-central-1" # Frankfurt — closest to Germany
}

# ------------------------------------------------------------
# NAMING
# All resource names are built as: "${var.project}-<resource>"
# e.g. "3tier-vpc", "3tier-web-sg"
# ------------------------------------------------------------

variable "project" {
  description = "Short prefix applied to every resource name for easy identification"
  type        = string
  default     = "3tier" # change this if you clone the repo for a different project
}

variable "environment" {
  description = "Deployment environment tag (dev / staging / prod)"
  type        = string
  default     = "dev"
}

# ------------------------------------------------------------
# VPC CIDR  (the big blue box in the diagram)
# 10.0.0.0/16 gives us 65 536 private IP addresses to carve up
# ------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the entire VPC"
  type        = string
  default     = "10.0.0.0/16" # matches the label in the diagram
}

# ------------------------------------------------------------
# SUBNET CIDRs
# Each /24 = 256 addresses (251 usable — AWS reserves 5)
# Diagram shows:
#   Web  AZ-1A → 10.0.1.0/24
#   Web  AZ-1B → 10.0.2.0/24
#   App  AZ-1A → 10.0.3.0/24
#   App  AZ-1B → 10.0.4.0/24
#   DB   AZ-1A → 10.0.5.0/24
#   DB   AZ-1B → 10.0.6.0/24  (not labeled but needed for RDS subnet group)
# ------------------------------------------------------------

variable "web_subnet_az1_cidr" {
  description = "CIDR for the public web subnet in AZ 1A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "web_subnet_az2_cidr" {
  description = "CIDR for the public web subnet in AZ 1B"
  type        = string
  default     = "10.0.2.0/24"
}

variable "app_subnet_az1_cidr" {
  description = "CIDR for the private app subnet in AZ 1A"
  type        = string
  default     = "10.0.3.0/24"
}

variable "app_subnet_az2_cidr" {
  description = "CIDR for the private app subnet in AZ 1B"
  type        = string
  default     = "10.0.4.0/24"
}

variable "db_subnet_az1_cidr" {
  description = "CIDR for the private database subnet in AZ 1A"
  type        = string
  default     = "10.0.5.0/24"
}

variable "db_subnet_az2_cidr" {
  description = "CIDR for the private database subnet in AZ 1B"
  type        = string
  default     = "10.0.6.0/24"
}

# ------------------------------------------------------------
# AVAILABILITY ZONES
# Diagram shows AZ 1A and AZ 1B — these are the real AWS names
# ------------------------------------------------------------

variable "az1" {
  description = "First availability zone"
  type        = string
  default     = "eu-central-1a"
}

variable "az2" {
  description = "Second availability zone"
  type        = string
  default     = "eu-central-1b"
}

# ------------------------------------------------------------
# EC2 INSTANCE TYPE
# t2.micro = FREE TIER eligible (750 hrs/month for 12 months)
# The diagram shows EC2 boxes in the web and app tiers
# ------------------------------------------------------------

variable "web_instance_type" {
  description = "EC2 instance type for web tier — t2.micro is free-tier eligible"
  type        = string
  default     = "t2.micro" # free tier: 750 hrs/month, 1 vCPU, 1 GB RAM
}

variable "app_instance_type" {
  description = "EC2 instance type for app tier — t2.micro is free-tier eligible"
  type        = string
  default     = "t2.micro"
}

# ------------------------------------------------------------
# AMI (Amazon Machine Image)
# This is the operating system image that EC2 boots from.
# Amazon Linux 2023 is free and well-supported.
# Find the latest ID in: EC2 → AMIs → filter "Amazon Linux 2023"
# The ID below is valid for us-east-1 — it changes per region.
# ------------------------------------------------------------

variable "ami_id" {
  description = "AMI ID for Amazon Linux 2023 in us-east-1"
  type        = string
  default     = "ami-0a628e1e89aaedf80" # Amazon Linux 2023, eu-central-1
}

# ------------------------------------------------------------
# RDS (database tier)
# db.t3.micro is the smallest free-tier eligible RDS class
# ------------------------------------------------------------

variable "db_instance_class" {
  description = "RDS instance class — db.t3.micro is free-tier eligible"
  type        = string
  default     = "db.t3.micro" # free tier: 750 hrs/month, 20 GB storage
}

variable "db_name" {
  description = "Name of the initial database created inside RDS"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password for the RDS instance — override this, never commit real passwords"
  type        = string
  default     = "ChangeMe123!" # ALWAYS override with a real secret in production
  sensitive   = true           # marks value as secret — Terraform hides it in output
}

# ------------------------------------------------------------
# S3 BUCKET NAME
# S3 bucket names are globally unique across all AWS accounts.
# The suffix below makes collisions unlikely — change it.
# ------------------------------------------------------------

variable "s3_bucket_name" {
  description = "Name for the S3 bucket — must be globally unique across all of AWS"
  type        = string
  default     = "3tier-app-assets-20240601" # change the suffix to something unique to you
}
