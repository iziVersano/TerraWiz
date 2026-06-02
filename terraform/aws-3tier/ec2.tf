# ============================================================
# ec2.tf
# Creates EC2 instances in the web and app tiers.
# Diagram: the orange "EC2 · auto scaling" boxes in each tier.
#
# COST: FREE — t2.micro is free tier eligible (750 hrs/month).
# Both instances together = 750 hrs/month free.
# If you run both at the same time you use 2x the free hours.
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
  ami                    = var.ami_id              # Amazon Linux 2023 in eu-central-1
  instance_type          = var.web_instance_type   # t2.micro — free tier
  subnet_id              = aws_subnet.web_az1.id   # place in public web subnet AZ1
  vpc_security_group_ids = [aws_security_group.web.id] # attach web SG — port 80 from ELB only
  associate_public_ip_address = true               # get a public IP — needed since no ELB

  user_data = <<-EOF
    #!/bin/bash
    # this script runs automatically when the EC2 first boots
    apt-get update -y                      # update all packages (Ubuntu uses apt not yum)
    apt-get install -y nginx               # install nginx web server
    systemctl start nginx                  # start nginx
    systemctl enable nginx                 # start nginx on reboot
    echo "<h1>3-tier Web Server - AZ1</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name        = "${var.project}-web-ec2"  # "3tier-web-ec2"
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
  ami                    = var.ami_id              # same AMI
  instance_type          = var.app_instance_type   # t2.micro — free tier
  subnet_id              = aws_subnet.app_az1.id   # place in PRIVATE app subnet AZ1
  vpc_security_group_ids = [aws_security_group.app.id] # attach app SG — port 3000 from web only
  associate_public_ip_address = false              # PRIVATE — no public IP

  user_data = <<-EOF
    #!/bin/bash
    # simple app server placeholder
    yum update -y
    yum install -y nodejs                  # install Node.js
    echo "const http = require('http'); http.createServer((req,res) => { res.end('App server OK'); }).listen(3000);" > /home/ec2-user/app.js
    node /home/ec2-user/app.js &           # start app on port 3000
  EOF

  tags = {
    Name        = "${var.project}-app-ec2"  # "3tier-app-ec2"
    Environment = var.environment
    Tier        = "app"
  }
}
