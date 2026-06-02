# ============================================================
# security.tf
# Creates 4 security groups — one per layer.
# Diagram: the "SG" boxes inside each tier.
#
# Traffic flow:
#   Internet → ELB SG → Web SG → App SG → DB SG
#
# Each layer only accepts traffic from the layer above it.
# This is the core security principle of 3-tier architecture.
# ============================================================

# ------------------------------------------------------------
# ELB SECURITY GROUP
# Diagram: "SG: allow 80, 443" on the ELB box
# Accepts HTTP from the internet — the only SG open to the world.
#
# AWS CLI equivalent:
#   aws ec2 create-security-group --group-name 3tier-elb-sg ...
#   aws ec2 authorize-security-group-ingress --group-id <id> --protocol tcp --port 80 --cidr 0.0.0.0/0
# ------------------------------------------------------------

resource "aws_security_group" "elb" {
  name        = "${var.project}-elb-sg"          # "3tier-elb-sg"
  description = "ELB - allow HTTP from internet"  # shown in the console
  vpc_id      = aws_vpc.main.id                   # attach to our VPC

  ingress {
    from_port   = 80              # allow port 80 (HTTP)
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # from anywhere on the internet
    description = "HTTP from internet"
  }

  egress {
    from_port   = 0             # allow ALL outbound traffic
    to_port     = 0
    protocol    = "-1"          # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }

  tags = {
    Name        = "${var.project}-elb-sg"
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# WEB TIER SECURITY GROUP
# Diagram: "SG · from ELB only" in the Web tier boxes
# Only accepts traffic that came through the ELB — not directly from internet.
#
# AWS CLI equivalent:
#   aws ec2 authorize-security-group-ingress --group-id <web-sg> \
#     --protocol tcp --port 80 --source-group <elb-sg>
# ------------------------------------------------------------

resource "aws_security_group" "web" {
  name        = "${var.project}-web-sg"
  description = "Web tier - allow traffic from ELB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80                              # port 80 (HTTP)
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.elb.id]    # ONLY from the ELB SG — not from the internet
    description     = "HTTP from ELB only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }

  tags = {
    Name        = "${var.project}-web-sg"
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# APP TIER SECURITY GROUP
# Diagram: "SG · from web tier SG" in the App tier boxes
# Only accepts traffic from the web tier EC2s.
#
# AWS CLI equivalent:
#   aws ec2 authorize-security-group-ingress --group-id <app-sg> \
#     --protocol tcp --port 3000 --source-group <web-sg>
# ------------------------------------------------------------

resource "aws_security_group" "app" {
  name        = "${var.project}-app-sg"
  description = "App tier - allow traffic from web tier only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3000                            # app runs on port 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]    # ONLY from the web tier SG
    description     = "App port from web tier only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }

  tags = {
    Name        = "${var.project}-app-sg"
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# DB TIER SECURITY GROUP
# Diagram: "SG · allow 3306 from app tier SG only" in the DB tier box
# Only accepts MySQL connections from the app tier.
# 3306 is the default MySQL/RDS port.
#
# AWS CLI equivalent:
#   aws ec2 authorize-security-group-ingress --group-id <db-sg> \
#     --protocol tcp --port 3306 --source-group <app-sg>
# ------------------------------------------------------------

resource "aws_security_group" "db" {
  name        = "${var.project}-db-sg"
  description = "DB tier - allow MySQL from app tier only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306                            # MySQL port
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]    # ONLY from the app tier SG
    description     = "MySQL from app tier only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }

  tags = {
    Name        = "${var.project}-db-sg"
    Environment = var.environment
  }
}
