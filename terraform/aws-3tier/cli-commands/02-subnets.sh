#!/bin/bash
# ============================================================
# 02-subnets.sh
# Creates 6 subnets across 2 AZs — web, app, db tiers.
# COST: FREE — subnets have no hourly charge.
# Console URL: https://console.aws.amazon.com/vpc/home?region=eu-central-1#subnets:
# ============================================================

source 00-ids.sh  # load VPC_ID and other saved IDs

# Web tier — PUBLIC (map_public_ip_on_launch added separately below)
aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone eu-central-1a --region eu-central-1 --profile admin --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=cli-3tier-web-az1},{Key=Tier,Value=web}]'
# Result: subnet-0abc6471f12f66e0f

aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone eu-central-1b --region eu-central-1 --profile admin --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=cli-3tier-web-az2},{Key=Tier,Value=web}]'
# Result: subnet-06f282be4c2c4e9a4

# Enable public IP on launch for web subnets (so EC2s get a public IP automatically)
aws ec2 modify-subnet-attribute --subnet-id subnet-0abc6471f12f66e0f --map-public-ip-on-launch --region eu-central-1 --profile admin
aws ec2 modify-subnet-attribute --subnet-id subnet-06f282be4c2c4e9a4 --map-public-ip-on-launch --region eu-central-1 --profile admin

# App tier — PRIVATE
aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.3.0/24 --availability-zone eu-central-1a --region eu-central-1 --profile admin --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=cli-3tier-app-az1},{Key=Tier,Value=app}]'
# Result: subnet-0bcbf3d486c6374b6

aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.4.0/24 --availability-zone eu-central-1b --region eu-central-1 --profile admin --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=cli-3tier-app-az2},{Key=Tier,Value=app}]'
# Result: subnet-05070f537838408de

# DB tier — PRIVATE
aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.5.0/24 --availability-zone eu-central-1a --region eu-central-1 --profile admin --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=cli-3tier-db-az1},{Key=Tier,Value=db}]'
# Result: subnet-060c0c92b95d2e0a8

aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.6.0/24 --availability-zone eu-central-1b --region eu-central-1 --profile admin --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=cli-3tier-db-az2},{Key=Tier,Value=db}]'
# Result: subnet-0cc1fe3c958637d29

# ============================================================
# DESTROY — delete all 6 subnets
# ============================================================
# aws ec2 delete-subnet --subnet-id subnet-0abc6471f12f66e0f --region eu-central-1 --profile admin
# aws ec2 delete-subnet --subnet-id subnet-06f282be4c2c4e9a4 --region eu-central-1 --profile admin
# aws ec2 delete-subnet --subnet-id subnet-0bcbf3d486c6374b6 --region eu-central-1 --profile admin
# aws ec2 delete-subnet --subnet-id subnet-05070f537838408de --region eu-central-1 --profile admin
# aws ec2 delete-subnet --subnet-id subnet-060c0c92b95d2e0a8 --region eu-central-1 --profile admin
# aws ec2 delete-subnet --subnet-id subnet-0cc1fe3c958637d29 --region eu-central-1 --profile admin
