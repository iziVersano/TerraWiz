output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.uploads.bucket
}

output "bucket_arn" {
  description = "S3 bucket ARN — used by IAM policy"
  value       = aws_s3_bucket.uploads.arn
}
