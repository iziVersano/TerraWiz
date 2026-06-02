# ============================================================
# ec2.tf
# Creates EC2 instances in the web and app tiers.
# Diagram: the orange "EC2 · auto scaling" boxes in each tier.
#
# COST: FREE — t2.micro is free tier eligible (750 hrs/month).
# Both instances together = 750 hrs/month free.
# If you run both at the same time you use 2x the free hours.
#
# NEW ENTITIES COVERED IN THIS FILE (from 2026-06-02 lesson):
#
# EBS (Elastic Block Store)
#   A persistent hard drive attached to an EC2 instance.
#   Like a USB drive plugged into your server — if the server stops,
#   the data stays. Survives reboots and stops. Deleted only when you say so.
#   Use for: OS, databases, application data, anything you can't afford to lose.
#
# EBS Volume Types:
#   gp3  — General Purpose SSD. Default choice. 3000 IOPS baseline, cheap.
#   gp2  — Older general purpose. gp3 is better and cheaper — always prefer gp3.
#   io2  — High performance SSD. For databases needing >16000 IOPS. Expensive.
#   st1  — Throughput optimised HDD. For big sequential reads (logs, data lakes).
#   sc1  — Cold HDD. Cheapest. For infrequently accessed data.
#
# Instance Store
#   Temporary storage physically attached to the HOST machine (not the EBS network).
#   Extremely fast — but LOST when the instance stops, terminates, or crashes.
#   Use for: caches, temp files, buffers — never for anything important.
#
# Snapshot
#   A point-in-time backup of an EBS volume stored in S3.
#   Like a photo of your hard drive at a specific moment.
#   Use to: restore a volume, copy to another region, create a Golden AMI.
#
# Golden AMI
#   An AMI (machine image) built from a snapshot that already has your app
#   pre-installed and configured. Instead of running a long user_data script
#   on every boot, you bake it once into the AMI and launch instantly.
#
# Lifecycle Policy
#   An automated rule that creates snapshots on a schedule (e.g. every hour)
#   and deletes old ones automatically. Set it and forget it.
#
# AWS CLI equivalent: see cli-commands/06-ec2.sh
# ============================================================

# ------------------------------------------------------------
# KEY PAIR (optional but recommended)
# Lets you SSH into the EC2 instances for debugging.
# Generate a key pair first:
#   ssh-keygen -t rsa -b 2048 -f ~/.ssh/3tier-key
# Then create it in AWS:
#   aws ec2 create-key-pair --key-name 3tier-key --region eu-central-1 --profile admin
# ------------------------------------------------------------

# ------------------------------------------------------------
# WEB TIER EC2 — AZ1
# Diagram: "EC2 · auto scaling / web server" in the Web · 10.0.1.0/24 box
# Lives in the PUBLIC subnet — gets a public IP automatically.
# Runs a simple web server (nginx via user_data script below).
#
# AWS CLI equivalent:
#   aws ec2 run-instances \
#     --image-id ami-0a628e1e89aaedf80 \
#     --instance-type t2.micro \
#     --subnet-id <web-az1-id> \
#     --security-group-ids <web-sg-id> \
#     --region eu-central-1 --profile admin
# ------------------------------------------------------------

resource "aws_instance" "web" {
  ami                         = var.ami_id                      # Amazon Linux 2023 in eu-central-1
  instance_type               = var.web_instance_type           # t2.micro — free tier
  subnet_id                   = aws_subnet.web_az1.id           # place in public web subnet AZ1
  vpc_security_group_ids      = [aws_security_group.web.id]     # attach web SG
  associate_public_ip_address = true                            # get a public IP — needed since no ELB

  # ------------------------------------------------------------
  # ROOT EBS VOLUME (gp3)
  # This is the OS disk — every EC2 has one automatically.
  # We explicitly define it here to:
  #   1. Choose gp3 (better and cheaper than the default gp2)
  #   2. Set a specific size (8 GB is enough for a web server)
  #   3. Enable encryption at rest
  # Console: EC2 → Instances → click instance → Storage tab
  # ------------------------------------------------------------
  root_block_device {
    volume_type           = "gp3"   # General Purpose SSD v3 — default best choice
    volume_size           = 8       # 8 GB — enough for OS + nginx
    encrypted             = true    # encrypt the volume at rest — best practice
    delete_on_termination = true    # delete EBS when EC2 is terminated — avoids orphan volumes
  }

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>3-tier Web Server - AZ1</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name        = "${var.project}-web-ec2"
    Environment = var.environment
    Tier        = "web"
  }
}

# ------------------------------------------------------------
# APP TIER EC2 — AZ1
# Diagram: "EC2 · auto scaling / app server" in the App · 10.0.3.0/24 box
# Lives in the PRIVATE subnet — no public IP.
# Only reachable from the web tier SG on port 3000.
#
# AWS CLI equivalent:
#   aws ec2 run-instances \
#     --image-id ami-0a628e1e89aaedf80 \
#     --instance-type t2.micro \
#     --subnet-id <app-az1-id> \
#     --security-group-ids <app-sg-id> \
#     --region eu-central-1 --profile admin
# ------------------------------------------------------------

resource "aws_instance" "app" {
  ami                         = var.ami_id                      # same AMI
  instance_type               = var.app_instance_type           # t2.micro — free tier
  subnet_id                   = aws_subnet.app_az1.id           # place in PRIVATE app subnet AZ1
  vpc_security_group_ids      = [aws_security_group.app.id]     # attach app SG
  associate_public_ip_address = false                           # PRIVATE — no public IP

  # ------------------------------------------------------------
  # ROOT EBS VOLUME (gp3)
  # App server needs slightly more space than web — Node.js + dependencies.
  # Same principle: gp3, encrypted, deleted on termination.
  # ------------------------------------------------------------
  root_block_device {
    volume_type           = "gp3"   # General Purpose SSD v3
    volume_size           = 8       # 8 GB — enough for app + Node.js
    encrypted             = true    # encrypt at rest
    delete_on_termination = true    # clean up when terminated
  }

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nodejs npm
    echo "const http = require('http'); http.createServer((req,res) => { res.end('App server OK'); }).listen(3000);" > /home/ubuntu/app.js
    node /home/ubuntu/app.js &
  EOF

  tags = {
    Name        = "${var.project}-app-ec2"
    Environment = var.environment
    Tier        = "app"
  }
}

# ------------------------------------------------------------
# EBS SNAPSHOT LIFECYCLE POLICY
# Automates taking snapshots of both EC2 volumes every day at 03:00 UTC.
# Keeps the last 7 snapshots — older ones deleted automatically.
# This is what the instructor called "lifecycle policy" — set and forget.
#
# What is a snapshot?
#   A point-in-time backup of an EBS volume stored in S3 (AWS manages it).
#   You can restore a volume from it, copy it to another region,
#   or use it to create a Golden AMI.
#
# COST: FREE for the policy itself.
#       Snapshots cost ~$0.05/GB/month — 8 GB × 7 snapshots = ~$2.80/month.
#       Delete old snapshots or reduce retention to save cost.
#
# Console: EC2 → Lifecycle Manager → Create lifecycle policy
# ------------------------------------------------------------

resource "aws_iam_role" "dlm" {
  name = "${var.project}-dlm-role"  # DLM = Data Lifecycle Manager

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "dlm.amazonaws.com" } # DLM service takes snapshots on our behalf
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dlm" {
  role       = aws_iam_role.dlm.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole" # AWS managed policy for DLM
}

resource "aws_dlm_lifecycle_policy" "ec2_snapshots" {
  description        = "Daily snapshots of web and app EC2 volumes"
  execution_role_arn = aws_iam_role.dlm.arn  # role DLM uses to create snapshots
  state              = "ENABLED"              # turn the policy on

  policy_details {
    resource_types = ["VOLUME"] # snapshot EBS volumes (not instances)

    schedule {
      name = "Daily snapshots — keep 7"

      create_rule {
        interval      = 24          # every 24 hours
        interval_unit = "HOURS"
        times         = ["03:00"]   # run at 03:00 UTC — low traffic time
      }

      retain_rule {
        count = 7   # keep the last 7 snapshots — older ones deleted automatically
      }

      copy_tags = true  # copy EC2 tags to snapshot so you know which instance it came from
    }

    target_tags = {
      Environment = var.environment  # snapshot all volumes whose EC2 has this tag
    }
  }

  tags = {
    Name        = "${var.project}-snapshot-policy"
    Environment = var.environment
  }
}
