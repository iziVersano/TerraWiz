# ============================================================
# subnets.tf
# Carves the VPC into 6 subnets across 2 AZs.
# Diagram: the 6 coloured boxes inside the VPC rectangle.
#
#   PUBLIC  (web tier)  — 10.0.1.0/24 (AZ1A)  10.0.2.0/24 (AZ1B)
#   PRIVATE (app tier)  — 10.0.3.0/24 (AZ1A)  10.0.4.0/24 (AZ1B)
#   PRIVATE (db tier)   — 10.0.5.0/24 (AZ1A)  10.0.6.0/24 (AZ1B)
# ============================================================

# ------------------------------------------------------------
# WEB TIER — PUBLIC SUBNETS
# Diagram: "Web · 10.0.1.0/24" (AZ 1A) and "Web · 10.0.2.0/24" (AZ 1B)
# These are PUBLIC — the ELB and web EC2s live here.
# map_public_ip_on_launch = true means EC2s get a public IP automatically.
# ------------------------------------------------------------

resource "aws_subnet" "web_az1" {
  vpc_id                  = aws_vpc.main.id        # place this subnet inside our VPC
  cidr_block              = var.web_subnet_az1_cidr # 10.0.1.0/24 from variables.tf
  availability_zone       = var.az1                 # us-east-1a
  map_public_ip_on_launch = true                    # EC2s here get a public IP automatically

  tags = {
    Name        = "${var.project}-web-az1" # "3tier-web-az1"
    Environment = var.environment
    Tier        = "web"                    # helps identify the tier at a glance
  }
}

resource "aws_subnet" "web_az2" {
  vpc_id                  = aws_vpc.main.id        # same VPC
  cidr_block              = var.web_subnet_az2_cidr # 10.0.2.0/24
  availability_zone       = var.az2                 # us-east-1b
  map_public_ip_on_launch = true                    # public subnet — same as web_az1

  tags = {
    Name        = "${var.project}-web-az2" # "3tier-web-az2"
    Environment = var.environment
    Tier        = "web"
  }
}

# ------------------------------------------------------------
# APP TIER — PRIVATE SUBNETS
# Diagram: "App · 10.0.3.0/24" (AZ 1A) and "App · 10.0.4.0/24" (AZ 1B)
# These are PRIVATE — no public IP, not reachable from the internet.
# Only the web tier can talk to these (enforced later in security.tf).
# ------------------------------------------------------------

resource "aws_subnet" "app_az1" {
  vpc_id                  = aws_vpc.main.id        # same VPC
  cidr_block              = var.app_subnet_az1_cidr # 10.0.3.0/24
  availability_zone       = var.az1                 # us-east-1a
  map_public_ip_on_launch = false                   # PRIVATE — no public IP assigned

  tags = {
    Name        = "${var.project}-app-az1" # "3tier-app-az1"
    Environment = var.environment
    Tier        = "app"
  }
}

resource "aws_subnet" "app_az2" {
  vpc_id                  = aws_vpc.main.id        # same VPC
  cidr_block              = var.app_subnet_az2_cidr # 10.0.4.0/24
  availability_zone       = var.az2                 # us-east-1b
  map_public_ip_on_launch = false                   # PRIVATE

  tags = {
    Name        = "${var.project}-app-az2" # "3tier-app-az2"
    Environment = var.environment
    Tier        = "app"
  }
}

# ------------------------------------------------------------
# DB TIER — PRIVATE SUBNETS
# Diagram: "DB tier · 10.0.5.0/24 · spans both AZs"
# RDS requires subnets in at least 2 AZs — that is why we need
# both db_az1 and db_az2 even though the diagram only labels one CIDR.
# These are the most locked-down subnets — only the app tier can reach them.
# ------------------------------------------------------------

resource "aws_subnet" "db_az1" {
  vpc_id                  = aws_vpc.main.id       # same VPC
  cidr_block              = var.db_subnet_az1_cidr # 10.0.5.0/24
  availability_zone       = var.az1                # us-east-1a — RDS primary lives here
  map_public_ip_on_launch = false                  # PRIVATE — database must never be public

  tags = {
    Name        = "${var.project}-db-az1" # "3tier-db-az1"
    Environment = var.environment
    Tier        = "db"
  }
}

resource "aws_subnet" "db_az2" {
  vpc_id                  = aws_vpc.main.id       # same VPC
  cidr_block              = var.db_subnet_az2_cidr # 10.0.6.0/24
  availability_zone       = var.az2                # us-east-1b — RDS replica lives here
  map_public_ip_on_launch = false                  # PRIVATE

  tags = {
    Name        = "${var.project}-db-az2" # "3tier-db-az2"
    Environment = var.environment
    Tier        = "db"
  }
}

# ------------------------------------------------------------
# RDS SUBNET GROUP
# RDS does not accept individual subnets — it needs a "subnet group"
# which is just a named collection of subnets it is allowed to use.
# We give it both DB subnets so RDS can place primary in AZ1
# and replica in AZ2.
# ------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name        = "${var.project}-db-subnet-group"      # "3tier-db-subnet-group"
  description = "Subnet group for RDS across both AZs" # shown in the console
  subnet_ids  = [                                      # list of subnet IDs to include
    aws_subnet.db_az1.id,                              # DB subnet in AZ 1A
    aws_subnet.db_az2.id,                              # DB subnet in AZ 1B
  ]

  tags = {
    Name        = "${var.project}-db-subnet-group"
    Environment = var.environment
  }
}
