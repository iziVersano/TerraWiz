#!/bin/bash
# ============================================================
# 01-vpc.sh
# Creates the VPC and Internet Gateway.
# COST: FREE — VPC and IGW have no hourly charge.
# Console URL: https://console.aws.amazon.com/vpc/home?region=eu-central-1#vpcs:
# IGW URL:     https://console.aws.amazon.com/vpc/home?region=eu-central-1#igws:
# ============================================================

# STEP 1 — Create VPC (the big blue box in the diagram)
aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --region eu-central-1 \
  --profile admin \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=cli-3tier-vpc}]'
# Result: vpc-01fb3a82c2c312b2a

# STEP 2 — Create Internet Gateway (the green IGW box)
aws ec2 create-internet-gateway \
  --region eu-central-1 \
  --profile admin \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=cli-3tier-igw}]'
# Result: igw-0b6b0ce19a92c46f8

# STEP 3 — Attach IGW to VPC (without this the VPC has no internet access)
aws ec2 attach-internet-gateway \
  --internet-gateway-id igw-0b6b0ce19a92c46f8 \
  --vpc-id vpc-01fb3a82c2c312b2a \
  --region eu-central-1 \
  --profile admin

# ============================================================
# DESTROY — run this to delete VPC and IGW (must detach first)
# ============================================================
# aws ec2 detach-internet-gateway --internet-gateway-id igw-0b6b0ce19a92c46f8 --vpc-id vpc-01fb3a82c2c312b2a --region eu-central-1 --profile admin
# aws ec2 delete-internet-gateway --internet-gateway-id igw-0b6b0ce19a92c46f8 --region eu-central-1 --profile admin
# aws ec2 delete-vpc --vpc-id vpc-01fb3a82c2c312b2a --region eu-central-1 --profile admin
