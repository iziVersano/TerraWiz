#!/bin/bash
# ============================================================
# 08-s3.sh
# Creates S3 bucket and VPC Gateway Endpoint.
# COST: FREE — 5 GB free tier, endpoint is always free.
# S3 URL:      https://s3.console.aws.amazon.com/s3/buckets?region=eu-central-1
# Endpoint URL: https://console.aws.amazon.com/vpc/home?region=eu-central-1#Endpoints:
# ============================================================

source 00-ids.sh

# STEP 1 — Create S3 bucket (name must be globally unique)
aws s3api create-bucket \
  --bucket cli-3tier-app-assets-20260602 \
  --region eu-central-1 \
  --create-bucket-configuration LocationConstraint=eu-central-1 \
  --profile admin
# Result: cli-3tier-app-assets-20260602

# STEP 2 — Block all public access
aws s3api put-public-access-block \
  --bucket cli-3tier-app-assets-20260602 \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
  --region eu-central-1 --profile admin

# STEP 3 — Create VPC Gateway Endpoint (private path from VPC to S3)
aws ec2 create-vpc-endpoint \
  --vpc-id $VPC_ID \
  --service-name com.amazonaws.eu-central-1.s3 \
  --route-table-ids $RT_PUBLIC_ID \
  --region eu-central-1 --profile admin
# Result: vpce-0e1b68331b0c30d04

S3_BUCKET="cli-3tier-app-assets-20260602"
S3_ENDPOINT_ID="vpce-0e1b68331b0c30d04"

# ============================================================
# DESTROY
# ============================================================
# aws s3 rb s3://cli-3tier-app-assets-20260602 --force --profile admin
# aws ec2 delete-vpc-endpoints --vpc-endpoint-ids vpce-0e1b68331b0c30d04 --region eu-central-1 --profile admin
