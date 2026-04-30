resource "aws_s3_bucket" "uploads" {
  bucket        = "${var.project_name}-uploads"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-uploads"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Block all public access — files are only accessible via the app
resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket                  = aws_s3_bucket.uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Auto-delete files after 30 days to stay within free tier
resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    id     = "expire-uploads"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }
  }
}
