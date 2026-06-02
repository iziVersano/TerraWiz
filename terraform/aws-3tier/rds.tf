# ============================================================
# rds.tf
# Creates the RDS MySQL database in the private DB subnet.
# Diagram: "RDS primary" box in the DB tier.
#
# COST: FREE — db.t3.micro is free tier (750 hrs/month, 20 GB storage).
#
# NOTE: The diagram shows RDS primary + replica across 2 AZs.
# Multi-AZ replica is NOT free (~$0.034/hr extra).
# We create a single instance only — add replica when course covers HA.
#
# ⚠️  THIS WILL INCUR CHARGES — Multi-AZ replica — DO NOT APPLY
#     resource "aws_db_instance" "replica" { ... replicate_source_db = ... }
#     Free alternative: single instance is fine for learning.
# ============================================================

# ------------------------------------------------------------
# RDS INSTANCE
# Diagram: "RDS primary · AZ 1A" box in the DB tier
# Lives in the private DB subnet — only the app tier can reach it.
#
# AWS CLI equivalent:
#   aws rds create-db-instance \
#     --db-instance-identifier 3tier-db \
#     --db-instance-class db.t3.micro \
#     --engine mysql \
#     --master-username admin \
#     --master-user-password ChangeMe123! \
#     --allocated-storage 20 \
#     --db-subnet-group-name 3tier-db-subnet-group \
#     --vpc-security-group-ids <db-sg-id> \
#     --no-publicly-accessible \
#     --region eu-central-1 --profile admin
# ------------------------------------------------------------

resource "aws_db_instance" "main" {
  identifier        = "${var.project}-db"    # "3tier-db" — shown in console
  engine            = "mysql"                # MySQL database engine
  engine_version    = "8.0"                 # MySQL version 8
  instance_class    = var.db_instance_class  # db.t3.micro — free tier
  allocated_storage = 20                     # 20 GB — minimum and free tier limit

  db_name  = var.db_name     # "appdb" — name of the initial database
  username = var.db_username  # master username
  password = var.db_password  # master password — sensitive, hidden in output

  db_subnet_group_name   = aws_db_subnet_group.main.name          # use our private DB subnets
  vpc_security_group_ids = [aws_security_group.db.id]             # only app tier can connect
  publicly_accessible    = false                                   # PRIVATE — no public endpoint

  skip_final_snapshot = true   # don't create a snapshot when destroyed — saves cost
  deletion_protection = false  # allow terraform destroy to delete it

  tags = {
    Name        = "${var.project}-db"
    Environment = var.environment
    Tier        = "db"
  }
}
