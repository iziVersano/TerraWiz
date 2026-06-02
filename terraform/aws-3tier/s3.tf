# ============================================================
# s3.tf
# Creates the S3 bucket and VPC Gateway Endpoint.
# Diagram: the "S3 bucket" and "VPC Gateway Endpoint" boxes at the bottom.
#
# COST: FREE
#   S3      → 5 GB free tier, 20,000 GET requests, 2,000 PUT requests/month
#   Endpoint → always free — no hourly charge, no data charge
# ============================================================

# ------------------------------------------------------------
# S3 BUCKET
# Diagram: the green "S3 bucket" box at the very bottom.
# Stores files uploaded by the app tier (images, documents etc).
# Bucket names must be globally unique across ALL AWS accounts.
#
# AWS CLI equivalent:
#   aws s3api create-bucket \
#     --bucket <your-unique-name> \
#     --region eu-central-1 \
#     --create-bucket-configuration LocationConstraint=eu-central-1 \
#     --profile admin
# ------------------------------------------------------------

resource "aws_s3_bucket" "main" {
  bucket        = var.s3_bucket_name  # must be globally unique — set in variables.tf
  force_destroy = true                # allow terraform destroy to delete even if bucket has files

  tags = {
    Name        = var.s3_bucket_name
    Environment = var.environment
    Tier        = "storage"
  }
}

# ------------------------------------------------------------
# BLOCK ALL PUBLIC ACCESS
# Nobody on the internet can read or write to this bucket.
# Only the app tier EC2s can access it via the VPC endpoint.
#
# AWS CLI equivalent:
#   aws s3api put-public-access-block \
#     --bucket <bucket-name> \
#     --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
#     --profile admin
# ------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.main.id # apply to our bucket
  block_public_acls       = true                  # block any public ACL grants
  block_public_policy     = true                  # block any public bucket policies
  ignore_public_acls      = true                  # ignore existing public ACLs
  restrict_public_buckets = true                  # restrict public bucket access
}

# ------------------------------------------------------------
# VPC GATEWAY ENDPOINT FOR S3
# Diagram: the "VPC Gateway Endpoint" box above the S3 bucket.
# Creates a private route from the VPC to S3 — no internet needed.
# Traffic from EC2s to S3 stays inside AWS backbone network.
#
# AWS CLI equivalent:
#   aws ec2 create-vpc-endpoint \
#     --vpc-id <vpc-id> \
#     --service-name com.amazonaws.eu-central-1.s3 \
#     --route-table-ids <public-rt-id> \
#     --region eu-central-1 --profile admin
# ------------------------------------------------------------

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id                          # attach to our VPC
  service_name      = "com.amazonaws.${var.aws_region}.s3"    # S3 endpoint for eu-central-1
  vpc_endpoint_type = "Gateway"                                # Gateway type — free, for S3 and DynamoDB only

  route_table_ids = [aws_route_table.public.id] # add S3 route to the public route table

  tags = {
    Name        = "${var.project}-s3-endpoint"  # "3tier-s3-endpoint"
    Environment = var.environment
  }
}
