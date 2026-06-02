# ============================================================
# route_tables.tf
# Tells traffic inside each subnet where to go.
# Diagram: the arrows from Web subnets → IGW
#
# AWS CLI equivalent:
#   1. Create route table:
#      aws ec2 create-route-table --vpc-id <vpc-id> --profile admin
#   2. Add route to IGW:
#      aws ec2 create-route --route-table-id <rt-id> --destination-cidr-block 0.0.0.0/0 --gateway-id <igw-id> --profile admin
#   3. Associate with subnet:
#      aws ec2 associate-route-table --route-table-id <rt-id> --subnet-id <subnet-id> --profile admin
# ============================================================

# ------------------------------------------------------------
# PUBLIC ROUTE TABLE
# Diagram: the arrow from Web tier → IGW
# This table has one rule: send all internet traffic (0.0.0.0/0) to the IGW.
# We attach it to both web subnets so EC2s there can reach the internet.
#
# AWS CLI:
#   aws ec2 create-route-table \
#     --vpc-id $(terraform output -raw vpc_id) \
#     --region eu-central-1 --profile admin \
#     --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=3tier-public-rt}]'
# ------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id # attach this route table to our VPC

  route {
    cidr_block = "0.0.0.0/0"             # match ALL traffic (any destination IP)
    gateway_id = aws_internet_gateway.main.id # send it to the IGW — out to the internet
  }

  tags = {
    Name        = "${var.project}-public-rt" # "3tier-public-rt"
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# ASSOCIATE PUBLIC ROUTE TABLE WITH WEB SUBNET AZ1
# Diagram: the arrow from "Web · 10.0.1.0/24" → IGW
# Without this association, the route table exists but has no effect.
#
# AWS CLI:
#   aws ec2 associate-route-table \
#     --route-table-id <rt-id> \
#     --subnet-id <web-az1-subnet-id> \
#     --region eu-central-1 --profile admin
# ------------------------------------------------------------

resource "aws_route_table_association" "web_az1" {
  subnet_id      = aws_subnet.web_az1.id      # the web subnet in AZ 1A
  route_table_id = aws_route_table.public.id  # link it to the public route table above
}

# ------------------------------------------------------------
# ASSOCIATE PUBLIC ROUTE TABLE WITH WEB SUBNET AZ2
# Diagram: the arrow from "Web · 10.0.2.0/24" → IGW
#
# AWS CLI:
#   aws ec2 associate-route-table \
#     --route-table-id <rt-id> \
#     --subnet-id <web-az2-subnet-id> \
#     --region eu-central-1 --profile admin
# ------------------------------------------------------------

resource "aws_route_table_association" "web_az2" {
  subnet_id      = aws_subnet.web_az2.id      # the web subnet in AZ 1B
  route_table_id = aws_route_table.public.id  # same public route table — both web subnets share it
}

# ------------------------------------------------------------
# PRIVATE SUBNETS (App + DB)
# These subnets have NO route table association to the IGW.
# AWS gives every subnet a default "local" route automatically:
#   10.0.0.0/16 → local  (traffic stays inside the VPC)
# That is all private subnets need — they can talk to each other
# inside the VPC but cannot reach the internet directly.
#
# NOTE: In production you would add a NAT Gateway here so private
# EC2s can reach the internet for updates/patches — but NAT Gateway
# costs ~$0.045/hr. We are skipping it to stay free-tier.
# If you needed it the Terraform would be:
#
#   THIS WILL INCUR CHARGES — DO NOT APPLY
#   Free alternative: use VPC Endpoints for AWS services,
#   or do updates during a maintenance window via a bastion host.
#
#   resource "aws_eip" "nat" { domain = "vpc" }
#
#   resource "aws_nat_gateway" "main" {
#     allocation_id = aws_eip.nat.id
#     subnet_id     = aws_subnet.web_az1.id  # NAT lives in a PUBLIC subnet
#   }
#
#   resource "aws_route_table" "private" {
#     vpc_id = aws_vpc.main.id
#     route {
#       cidr_block     = "0.0.0.0/0"
#       nat_gateway_id = aws_nat_gateway.main.id
#     }
#   }
# ------------------------------------------------------------
