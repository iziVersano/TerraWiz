#!/bin/bash
# ============================================================
# 03-route-tables.sh
# Creates public route table and associates with web subnets.
# COST: FREE — route tables have no hourly charge.
# Console URL: https://console.aws.amazon.com/vpc/home?region=eu-central-1#routetables:
# ============================================================

source 00-ids.sh  # load VPC_ID, IGW_ID, WEB_AZ1_ID, WEB_AZ2_ID

# STEP 1 — Create public route table
aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --region eu-central-1 \
  --profile admin \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=cli-3tier-public-rt}]'
# Result: rtb-073f8ae390e2bb214

# STEP 2 — Add route: all internet traffic (0.0.0.0/0) → IGW
aws ec2 create-route \
  --route-table-id rtb-073f8ae390e2bb214 \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID \
  --region eu-central-1 \
  --profile admin

# STEP 3 — Associate with both web subnets
aws ec2 associate-route-table --route-table-id rtb-073f8ae390e2bb214 --subnet-id $WEB_AZ1_ID --region eu-central-1 --profile admin
aws ec2 associate-route-table --route-table-id rtb-073f8ae390e2bb214 --subnet-id $WEB_AZ2_ID --region eu-central-1 --profile admin

# NOTE: App and DB subnets stay on the default local route — no internet access.
# NO NAT GATEWAY — that would cost ~$0.045/hr. Skipped to stay free.

# ============================================================
# DESTROY
# ============================================================
# aws ec2 disassociate-route-table --association-id rtbassoc-0c8ccff9d9bea7ebb --region eu-central-1 --profile admin
# aws ec2 disassociate-route-table --association-id rtbassoc-09d86718b48a5357d --region eu-central-1 --profile admin
# aws ec2 delete-route-table --route-table-id rtb-073f8ae390e2bb214 --region eu-central-1 --profile admin
