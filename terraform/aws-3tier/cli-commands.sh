#!/bin/bash
# ============================================================
# cli-commands.sh
# Every AWS CLI command we ran to build the CLI 3-tier architecture.
# Resources are prefixed with "cli-3tier-" to separate them from
# the Terraform version which uses "3tier-".
#
# NOTE: These commands were already run — this is a record, not a script to re-run.
# If you want to re-run from scratch, destroy the CLI resources first.
# ============================================================

# ------------------------------------------------------------
# STEP 1 — VPC
# Console: VPC → Your VPCs
# URL: https://console.aws.amazon.com/vpc/home?region=eu-central-1#vpcs:
# Result: vpc-01fb3a82c2c312b2a
# ------------------------------------------------------------
aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --region eu-central-1 \
  --profile admin \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=cli-3tier-vpc}]'

# Saved IDs
VPC_ID="vpc-01fb3a82c2c312b2a"

# ------------------------------------------------------------
# STEP 2 — Internet Gateway
# Console: VPC → Internet Gateways
# URL: https://console.aws.amazon.com/vpc/home?region=eu-central-1#igws:
# Result: igw-0b6b0ce19a92c46f8 — attached to vpc-01fb3a82c2c312b2a
# ------------------------------------------------------------
aws ec2 create-internet-gateway \
  --region eu-central-1 \
  --profile admin \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=cli-3tier-igw}]'

aws ec2 attach-internet-gateway \
  --internet-gateway-id igw-0b6b0ce19a92c46f8 \
  --vpc-id vpc-01fb3a82c2c312b2a \
  --region eu-central-1 \
  --profile admin

IGW_ID="igw-0b6b0ce19a92c46f8"

# ------------------------------------------------------------
# STEP 3 — Subnets (6 total)
# Console: VPC → Subnets
# URL: https://console.aws.amazon.com/vpc/home?region=eu-central-1#subnets:
# ------------------------------------------------------------
# Web AZ1 → subnet-0abc6471f12f66e0f  (10.0.1.0/24 eu-central-1a)
# Web AZ2 → subnet-06f282be4c2c4e9a4  (10.0.2.0/24 eu-central-1b)
# App AZ1 → subnet-0bcbf3d486c6374b6  (10.0.3.0/24 eu-central-1a)
# App AZ2 → subnet-05070f537838408de  (10.0.4.0/24 eu-central-1b)
# DB  AZ1 → subnet-060c0c92b95d2e0a8  (10.0.5.0/24 eu-central-1a)
# DB  AZ2 → subnet-0cc1fe3c958637d29  (10.0.6.0/24 eu-central-1b)

WEB_AZ1_ID="subnet-0abc6471f12f66e0f"
WEB_AZ2_ID="subnet-06f282be4c2c4e9a4"
APP_AZ1_ID="subnet-0bcbf3d486c6374b6"
APP_AZ2_ID="subnet-05070f537838408de"
DB_AZ1_ID="subnet-060c0c92b95d2e0a8"
DB_AZ2_ID="subnet-0cc1fe3c958637d29"

# ------------------------------------------------------------
# STEP 4 — Route Tables
# Console: VPC → Route Tables
# URL: https://console.aws.amazon.com/vpc/home?region=eu-central-1#routetables:
# ------------------------------------------------------------
# Public RT → rtb-073f8ae390e2bb214
# Route: 0.0.0.0/0 → igw-0b6b0ce19a92c46f8
# Associated with: web-az1, web-az2

RT_PUBLIC_ID="rtb-073f8ae390e2bb214"

# ------------------------------------------------------------
# STEP 5 — Security Groups
# Console: VPC → Security Groups
# URL: https://console.aws.amazon.com/vpc/home?region=eu-central-1#securityGroups:
# ------------------------------------------------------------
# ELB SG  → sg-07309813773224fb9  (port 80 from 0.0.0.0/0)
# Web SG  → sg-0a8eefe3715606be0  (port 80 from ELB SG)
# App SG  → sg-0fa4157863ea81a4c  (port 3000 from Web SG)
# DB SG   → sg-0eff7ca410b56b89e  (port 3306 from App SG)

ELB_SG_ID="sg-07309813773224fb9"
WEB_SG_ID="sg-0a8eefe3715606be0"
APP_SG_ID="sg-0fa4157863ea81a4c"
DB_SG_ID="sg-0eff7ca410b56b89e"
