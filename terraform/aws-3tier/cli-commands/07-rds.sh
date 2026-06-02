#!/bin/bash
# ============================================================
# 07-rds.sh
# Creates RDS MySQL instance in the private DB subnet.
# COST: FREE — db.t3.micro free tier (750 hrs/month, 20 GB).
# Console URL: https://console.aws.amazon.com/rds/home?region=eu-central-1#databases:
#
# ⚠️  Takes 5-10 minutes to become available.
# ⚠️  STOP when not studying — RDS charges by the hour even on free tier
#     after the 750 hrs/month limit is reached.
# ============================================================

source 00-ids.sh

# STEP 1 — Create DB subnet group (RDS needs subnets in 2 AZs)
aws rds create-db-subnet-group \
  --db-subnet-group-name cli-3tier-db-subnet-group \
  --db-subnet-group-description "DB subnet group for cli-3tier" \
  --subnet-ids $DB_AZ1_ID $DB_AZ2_ID \
  --region eu-central-1 --profile admin
# Result: cli-3tier-db-subnet-group

# STEP 2 — Create RDS MySQL instance
aws rds create-db-instance \
  --db-instance-identifier cli-3tier-db \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --engine-version 8.0 \
  --master-username admin \
  --master-user-password ChangeMe123! \
  --allocated-storage 20 \
  --db-subnet-group-name cli-3tier-db-subnet-group \
  --vpc-security-group-ids $DB_SG_ID \
  --no-publicly-accessible \
  --db-name appdb \
  --region eu-central-1 --profile admin
# Result: cli-3tier-db (creating → available after ~5-10 min)

RDS_ID="cli-3tier-db"

# STEP 3 — Check status (run until it shows "available")
# aws rds describe-db-instances --db-instance-identifier cli-3tier-db --region eu-central-1 --profile admin --query 'DBInstances[0].DBInstanceStatus' --output text

# ============================================================
# STOP (saves free tier hours — always stop when not studying)
# aws rds stop-db-instance --db-instance-identifier cli-3tier-db --region eu-central-1 --profile admin
#
# START
# aws rds start-db-instance --db-instance-identifier cli-3tier-db --region eu-central-1 --profile admin
#
# DESTROY
# aws rds delete-db-instance --db-instance-identifier cli-3tier-db --skip-final-snapshot --region eu-central-1 --profile admin
# aws rds delete-db-subnet-group --db-subnet-group-name cli-3tier-db-subnet-group --region eu-central-1 --profile admin
# ============================================================
