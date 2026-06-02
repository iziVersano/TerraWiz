#!/bin/bash
# ============================================================
# 06-ec2.sh
# Creates web and app tier EC2 instances.
# COST: FREE — t2.micro is free tier (750 hrs/month).
# Console URL: https://console.aws.amazon.com/ec2/home?region=eu-central-1#Instances:
#
# Web EC2: cli-3tier-web-ec2 → i-0d609ba80ee3bd80d (public IP: 3.67.193.169)
# App EC2: cli-3tier-app-ec2 → i-055ea4e91f0c3578f (private only)
# ============================================================

source 00-ids.sh

# STEP 1 — Web EC2 in public subnet (gets a public IP)
aws ec2 run-instances \
  --image-id ami-0a628e1e89aaedf80 \
  --instance-type t2.micro \
  --subnet-id $WEB_AZ1_ID \
  --security-group-ids $WEB_SG_ID \
  --associate-public-ip-address \
  --region eu-central-1 --profile admin \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cli-3tier-web-ec2},{Key=Tier,Value=web}]'
# Result: i-0d609ba80ee3bd80d  Public IP: 3.67.193.169

# STEP 2 — App EC2 in private subnet (no public IP)
aws ec2 run-instances \
  --image-id ami-0a628e1e89aaedf80 \
  --instance-type t2.micro \
  --subnet-id $APP_AZ1_ID \
  --security-group-ids $APP_SG_ID \
  --no-associate-public-ip-address \
  --region eu-central-1 --profile admin \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cli-3tier-app-ec2},{Key=Tier,Value=app}]'
# Result: i-055ea4e91f0c3578f  Private only

WEB_EC2_ID="i-0d609ba80ee3bd80d"
WEB_EC2_IP="3.67.193.169"
APP_EC2_ID="i-055ea4e91f0c3578f"

# ============================================================
# DESTROY
# ============================================================
# aws ec2 terminate-instances --instance-ids i-0d609ba80ee3bd80d i-055ea4e91f0c3578f --region eu-central-1 --profile admin
