#!/bin/bash
# ============================================================
# 06-ec2.sh
# Creates web and app tier EC2 instances with EBS volumes,
# snapshots, and a lifecycle policy for automated backups.
# COST: FREE for EC2 (t2.micro free tier).
#       Snapshots ~$0.05/GB/month — small cost, delete when done.
#
# Console URLs:
#   Instances:        https://console.aws.amazon.com/ec2/home?region=eu-central-1#Instances:
#   Volumes:          https://console.aws.amazon.com/ec2/home?region=eu-central-1#Volumes:
#   Snapshots:        https://console.aws.amazon.com/ec2/home?region=eu-central-1#Snapshots:
#   Lifecycle Mgr:    https://console.aws.amazon.com/ec2/home?region=eu-central-1#LifecycleManager:
#   AMIs:             https://console.aws.amazon.com/ec2/home?region=eu-central-1#Images:
#
# ============================================================
# ENTITIES EXPLAINED
#
# EC2 (Elastic Compute Cloud)
#   A virtual server you rent by the hour. You choose the OS, CPU, RAM.
#   When you stop it you stop paying for compute (but EBS storage continues).
#
# EBS (Elastic Block Store)
#   A persistent network-attached hard drive for your EC2.
#   Like a USB drive — plug it in, use it, unplug it, plug it into another EC2.
#   Data survives stops and reboots. Only deleted when you explicitly delete it.
#   Lives in ONE availability zone — cannot be shared across AZs directly.
#
# EBS Volume Types (choose based on your workload):
#   gp3  → General Purpose SSD. Best default. 3000 IOPS, 125 MB/s. Cheapest SSD.
#   gp2  → Older general purpose. IOPS tied to size. Always use gp3 instead.
#   io2  → High performance SSD. Up to 64000 IOPS. For demanding databases only.
#   st1  → Throughput HDD. Cheap, sequential reads. Good for logs and data lakes.
#   sc1  → Cold HDD. Cheapest. For data you rarely access.
#
# Instance Store
#   Physical storage on the HOST machine running your EC2.
#   EXTREMELY fast — no network hop. But GONE when instance stops or crashes.
#   Use ONLY for: caches, temp files, scratch space. NEVER for important data.
#
# Snapshot
#   A point-in-time backup of an EBS volume. Stored in S3 (AWS manages it).
#   Incremental — first snapshot copies everything, later ones copy only changes.
#   Use to: restore a lost volume, move data to another region, create a Golden AMI.
#
# Golden AMI
#   A custom machine image built from a snapshot with your app pre-installed.
#   Instead of running user_data scripts on every boot (slow), you bake
#   everything in once and launch instantly from the Golden AMI.
#   The instructor's example: update your app weekly, bake a new Golden AMI,
#   launch all new instances from it — no boot-time installs needed.
#
# Lifecycle Policy (DLM — Data Lifecycle Manager)
#   An automated rule that creates and deletes snapshots on a schedule.
#   Example: create a snapshot every day at 03:00, keep the last 7, delete older ones.
#   Console: EC2 → Lifecycle Manager
# ============================================================

source 00-ids.sh

# ------------------------------------------------------------
# STEP 1 — Launch Web EC2 with gp3 EBS root volume
# Public subnet — gets a public IP automatically
# ------------------------------------------------------------
aws ec2 run-instances \
  --image-id ami-0a628e1e89aaedf80 \
  --instance-type t2.micro \
  --subnet-id $WEB_AZ1_ID \
  --security-group-ids $WEB_SG_ID \
  --associate-public-ip-address \
  --block-device-mappings '[{
    "DeviceName": "/dev/sda1",
    "Ebs": {
      "VolumeSize": 8,
      "VolumeType": "gp3",
      "Encrypted": true,
      "DeleteOnTermination": true
    }
  }]' \
  --region eu-central-1 --profile admin \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cli-3tier-web-ec2},{Key=Tier,Value=web},{Key=Environment,Value=dev}]'
# Result: i-0d3c7bb27841044b2   Public IP: 18.159.113.182

# ------------------------------------------------------------
# STEP 2 — Launch App EC2 with gp3 EBS root volume
# Private subnet — no public IP
# ------------------------------------------------------------
aws ec2 run-instances \
  --image-id ami-0a628e1e89aaedf80 \
  --instance-type t2.micro \
  --subnet-id $APP_AZ1_ID \
  --security-group-ids $APP_SG_ID \
  --no-associate-public-ip-address \
  --block-device-mappings '[{
    "DeviceName": "/dev/sda1",
    "Ebs": {
      "VolumeSize": 8,
      "VolumeType": "gp3",
      "Encrypted": true,
      "DeleteOnTermination": true
    }
  }]' \
  --region eu-central-1 --profile admin \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=cli-3tier-app-ec2},{Key=Tier,Value=app},{Key=Environment,Value=dev}]'
# Result: i-055ea4e91f0c3578f   Private only

WEB_EC2_ID="i-0d3c7bb27841044b2"
WEB_EC2_IP="18.159.113.182"   # NOTE: changes every time you start the instance
APP_EC2_ID="i-055ea4e91f0c3578f"

# ------------------------------------------------------------
# STEP 3 — Create a manual snapshot of the web EC2 volume
# First get the volume ID attached to the web EC2, then snapshot it.
# In production you'd do this before stopping — it's your restore point.
# ------------------------------------------------------------

# Get the EBS volume ID attached to the web EC2
WEB_VOLUME_ID=$(aws ec2 describe-instances \
  --instance-ids $WEB_EC2_ID \
  --region eu-central-1 --profile admin \
  --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' \
  --output text)

# Create a snapshot of that volume
aws ec2 create-snapshot \
  --volume-id $WEB_VOLUME_ID \
  --description "Manual snapshot of cli-3tier-web-ec2 root volume" \
  --region eu-central-1 --profile admin \
  --tag-specifications 'ResourceType=snapshot,Tags=[{Key=Name,Value=cli-3tier-web-snapshot},{Key=Environment,Value=dev}]'
# Snapshot is PENDING then changes to COMPLETED — check in console

# ------------------------------------------------------------
# STEP 4 — Create a Golden AMI from the web EC2
# This captures the entire running state (OS + nginx + your config).
# Future instances launched from this AMI start instantly — no user_data needed.
# ------------------------------------------------------------
aws ec2 create-image \
  --instance-id $WEB_EC2_ID \
  --name "cli-3tier-web-golden-ami" \
  --description "Golden AMI — nginx pre-installed, web tier ready" \
  --no-reboot \
  --region eu-central-1 --profile admin
# Result: ami-xxxxxxxxxxxxxxxxx — check AMIs console, takes a few minutes

# ------------------------------------------------------------
# STEP 5 — Create a Lifecycle Policy (automated daily snapshots)
# Snapshots every day at 03:00 UTC, keep last 7.
# This replaces doing STEP 3 manually every day.
# Console: EC2 → Lifecycle Manager
# ------------------------------------------------------------
aws dlm create-lifecycle-policy \
  --description "Daily snapshots of 3tier EC2 volumes" \
  --state ENABLED \
  --execution-role-arn arn:aws:iam::302263067280:role/cli-3tier-dlm-role \
  --policy-details '{
    "ResourceTypes": ["VOLUME"],
    "TargetTags": [{"Key": "Environment", "Value": "dev"}],
    "Schedules": [{
      "Name": "Daily — keep 7",
      "CreateRule": {"Interval": 24, "IntervalUnit": "HOURS", "Times": ["03:00"]},
      "RetainRule": {"Count": 7},
      "CopyTags": true
    }]
  }' \
  --region eu-central-1 --profile admin

# ============================================================
# STOP (saves free tier hours)
# aws ec2 stop-instances --instance-ids $WEB_EC2_ID $APP_EC2_ID --region eu-central-1 --profile admin
#
# START
# aws ec2 start-instances --instance-ids $WEB_EC2_ID $APP_EC2_ID --region eu-central-1 --profile admin
#
# DESTROY
# aws ec2 terminate-instances --instance-ids $WEB_EC2_ID $APP_EC2_ID --region eu-central-1 --profile admin
# Delete snapshots manually: EC2 → Snapshots → select → delete
# Deregister AMI: EC2 → AMIs → select → deregister
# ============================================================
