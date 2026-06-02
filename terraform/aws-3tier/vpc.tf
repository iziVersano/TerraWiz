# ============================================================
# vpc.tf
# Creates the VPC and Internet Gateway.
# Diagram: the big blue "VPC · 10.0.0.0/16 · us-east-1" box
#          and the green "IGW" box above it.
# ============================================================

# ------------------------------------------------------------
# PROVIDER
# Tells Terraform which cloud to talk to and which credentials
# to use. The profile "admin" matches your ~/.aws/credentials.
# ------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" # official AWS provider from HashiCorp
      version = "~> 5.0"        # use any 5.x version
    }
  }
}

provider "aws" {
  region  = var.aws_region # reads from variables.tf — "us-east-1"
  profile = "admin"        # your personal AWS account credentials
}

# ------------------------------------------------------------
# VPC
# The big blue box in the diagram.
# Everything we build lives inside this boundary.
# ------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr # 10.0.0.0/16 — the whole address space
  enable_dns_support   = true         # lets AWS resolve DNS names inside the VPC
  enable_dns_hostnames = true         # gives EC2 instances a DNS hostname automatically

  tags = {
    Name        = "${var.project}-vpc" # e.g. "3tier-vpc"
    Environment = var.environment      # "dev"
  }
}

# ------------------------------------------------------------
# INTERNET GATEWAY
# The green "IGW" box at the top of the diagram.
# Attaches to the VPC and opens the front door to the internet.
# Without this, nothing inside the VPC can talk to the internet.
# ------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id # attaches this IGW to the VPC we just created above

  tags = {
    Name        = "${var.project}-igw" # e.g. "3tier-igw"
    Environment = var.environment
  }
}
