#!/bin/bash
# ============================================================
# 00-ids.sh
# All real AWS resource IDs created during this course.
# Source this file before running any other script:
#   source 00-ids.sh
#
# COST STATUS — everything here is FREE:
#   VPC                → FREE
#   Internet Gateway   → FREE
#   Subnets            → FREE
#   Route Tables       → FREE
#   Security Groups    → FREE
#   ELB                → ~$0.018/hr ⚠️  — destroy when not in use
#   EC2 t2.micro       → FREE (750 hrs/month free tier)
#   RDS db.t3.micro    → FREE (750 hrs/month free tier)
#   S3                 → FREE (5 GB free tier)
#   NAT Gateway        → NOT USED — would cost ~$0.045/hr
# ============================================================

# VPC
VPC_ID="vpc-01fb3a82c2c312b2a"

# Internet Gateway
IGW_ID="igw-0b6b0ce19a92c46f8"

# Subnets
WEB_AZ1_ID="subnet-0abc6471f12f66e0f"   # 10.0.1.0/24 eu-central-1a
WEB_AZ2_ID="subnet-06f282be4c2c4e9a4"   # 10.0.2.0/24 eu-central-1b
APP_AZ1_ID="subnet-0bcbf3d486c6374b6"   # 10.0.3.0/24 eu-central-1a
APP_AZ2_ID="subnet-05070f537838408de"   # 10.0.4.0/24 eu-central-1b
DB_AZ1_ID="subnet-060c0c92b95d2e0a8"    # 10.0.5.0/24 eu-central-1a
DB_AZ2_ID="subnet-0cc1fe3c958637d29"    # 10.0.6.0/24 eu-central-1b

# Route Tables
RT_PUBLIC_ID="rtb-073f8ae390e2bb214"

# Security Groups
ELB_SG_ID="sg-07309813773224fb9"
WEB_SG_ID="sg-0a8eefe3715606be0"
APP_SG_ID="sg-0fa4157863ea81a4c"
DB_SG_ID="sg-0eff7ca410b56b89e"

# EC2
WEB_EC2_ID="i-0d3c7bb27841044b2"
WEB_EC2_IP="18.159.113.182"  # note: IP changes on restart — check console for new IP
APP_EC2_ID="i-055ea4e91f0c3578f"

# ELB, RDS, S3 — added as we build them
# ELB_ARN=""
# RDS_ID=""
# S3_BUCKET=""
