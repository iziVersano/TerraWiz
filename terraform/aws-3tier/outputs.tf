# ============================================================
# outputs.tf
# Prints useful values after terraform apply completes.
# Run "terraform output" at any time to see these values again.
# ============================================================

# ------------------------------------------------------------
# VPC
# ------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

# ------------------------------------------------------------
# WEB TIER
# ------------------------------------------------------------

output "web_ec2_public_ip" {
  description = "Public IP of the web EC2 — open this in your browser"
  value       = aws_instance.web.public_ip
}

output "web_subnet_az1_id" {
  description = "ID of the web subnet in AZ1"
  value       = aws_subnet.web_az1.id
}

output "web_subnet_az2_id" {
  description = "ID of the web subnet in AZ2"
  value       = aws_subnet.web_az2.id
}

# ------------------------------------------------------------
# APP TIER
# ------------------------------------------------------------

output "app_ec2_private_ip" {
  description = "Private IP of the app EC2 — only reachable from web tier"
  value       = aws_instance.app.private_ip
}

# ------------------------------------------------------------
# DATABASE TIER
# ------------------------------------------------------------

output "rds_endpoint" {
  description = "RDS connection endpoint — use this in your app config"
  value       = aws_db_instance.main.endpoint
}

output "rds_port" {
  description = "RDS port — 3306 for MySQL"
  value       = aws_db_instance.main.port
}

# ------------------------------------------------------------
# S3
# ------------------------------------------------------------

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.main.bucket
}

output "s3_endpoint_id" {
  description = "VPC Gateway Endpoint ID for S3"
  value       = aws_vpc_endpoint.s3.id
}

# ------------------------------------------------------------
# QUICK REFERENCE — printed as a single block after apply
# ------------------------------------------------------------

output "summary" {
  description = "Quick reference — all key values in one place"
  value = <<-EOT

    ========================================
    3-TIER ARCHITECTURE — QUICK REFERENCE
    ========================================
    VPC:            ${aws_vpc.main.id}
    Web EC2 IP:     ${aws_instance.web.public_ip}  ← open in browser
    App EC2 IP:     ${aws_instance.app.private_ip} (private)
    RDS Endpoint:   ${aws_db_instance.main.endpoint}
    S3 Bucket:      ${aws_s3_bucket.main.bucket}
    ========================================
  EOT
}
