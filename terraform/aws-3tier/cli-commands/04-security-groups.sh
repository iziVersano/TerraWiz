#!/bin/bash
# ============================================================
# 04-security-groups.sh
# Creates 4 security groups — one per tier.
# COST: FREE — security groups have no hourly charge.
# Console URL: https://console.aws.amazon.com/vpc/home?region=eu-central-1#securityGroups:
#
# Traffic flow:
#   Internet → ELB SG (port 80) → Web SG (port 80) → App SG (port 3000) → DB SG (port 3306)
# ============================================================

source 00-ids.sh  # load VPC_ID

# STEP 1 — ELB SG: accepts port 80 from the internet
aws ec2 create-security-group --group-name cli-3tier-elb-sg --description "ELB - allow HTTP from internet" --vpc-id $VPC_ID --region eu-central-1 --profile admin --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=cli-3tier-elb-sg}]'
# Result: sg-07309813773224fb9

aws ec2 authorize-security-group-ingress --group-id sg-07309813773224fb9 --protocol tcp --port 80 --cidr 0.0.0.0/0 --region eu-central-1 --profile admin

# STEP 2 — Web SG: accepts port 80 from ELB SG only
aws ec2 create-security-group --group-name cli-3tier-web-sg --description "Web tier - allow traffic from ELB only" --vpc-id $VPC_ID --region eu-central-1 --profile admin --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=cli-3tier-web-sg}]'
# Result: sg-0a8eefe3715606be0

aws ec2 authorize-security-group-ingress --group-id sg-0a8eefe3715606be0 --protocol tcp --port 80 --source-group sg-07309813773224fb9 --region eu-central-1 --profile admin

# STEP 3 — App SG: accepts port 3000 from Web SG only
aws ec2 create-security-group --group-name cli-3tier-app-sg --description "App tier - allow traffic from web tier only" --vpc-id $VPC_ID --region eu-central-1 --profile admin --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=cli-3tier-app-sg}]'
# Result: sg-0fa4157863ea81a4c

aws ec2 authorize-security-group-ingress --group-id sg-0fa4157863ea81a4c --protocol tcp --port 3000 --source-group sg-0a8eefe3715606be0 --region eu-central-1 --profile admin

# STEP 4 — DB SG: accepts port 3306 (MySQL) from App SG only
aws ec2 create-security-group --group-name cli-3tier-db-sg --description "DB tier - allow MySQL from app tier only" --vpc-id $VPC_ID --region eu-central-1 --profile admin --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=cli-3tier-db-sg}]'
# Result: sg-0eff7ca410b56b89e

aws ec2 authorize-security-group-ingress --group-id sg-0eff7ca410b56b89e --protocol tcp --port 3306 --source-group sg-0fa4157863ea81a4c --region eu-central-1 --profile admin

# ============================================================
# DESTROY
# ============================================================
# aws ec2 delete-security-group --group-id sg-0eff7ca410b56b89e --region eu-central-1 --profile admin
# aws ec2 delete-security-group --group-id sg-0fa4157863ea81a4c --region eu-central-1 --profile admin
# aws ec2 delete-security-group --group-id sg-0a8eefe3715606be0 --region eu-central-1 --profile admin
# aws ec2 delete-security-group --group-id sg-07309813773224fb9 --region eu-central-1 --profile admin
# NOTE: delete in reverse order — DB first, ELB last — because of SG references
