#!/bin/bash
# ============================================================
# 99-destroy-all.sh
# Destroys ALL cli-3tier resources in the correct order.
# Run this when you are done to avoid any charges.
#
# ORDER MATTERS — delete dependencies before parents:
#   EC2/RDS → ELB → Security Groups → Subnets → Route Tables → IGW → VPC
# ============================================================

source 00-ids.sh

echo "WARNING: This will delete all cli-3tier resources in eu-central-1"
echo "Press ENTER to continue or Ctrl+C to cancel"
read

# ---- EC2 / ASG (added when we build ec2.tf) ----
# aws autoscaling delete-auto-scaling-group --auto-scaling-group-name cli-3tier-web-asg --force-delete --region eu-central-1 --profile admin
# aws autoscaling delete-auto-scaling-group --auto-scaling-group-name cli-3tier-app-asg --force-delete --region eu-central-1 --profile admin
# aws ec2 delete-launch-template --launch-template-name cli-3tier-web-lt --region eu-central-1 --profile admin
# aws ec2 delete-launch-template --launch-template-name cli-3tier-app-lt --region eu-central-1 --profile admin

# ---- RDS (added when we build rds.tf) ----
# aws rds delete-db-instance --db-instance-identifier cli-3tier-db --skip-final-snapshot --region eu-central-1 --profile admin

# ---- ELB (added when we build elb.tf) ----
# aws elbv2 delete-load-balancer --load-balancer-arn $ELB_ARN --region eu-central-1 --profile admin

# ---- S3 (added when we build s3.tf) ----
# aws s3 rb s3://$S3_BUCKET --force --region eu-central-1 --profile admin

# ---- Security Groups (delete in reverse — DB first, ELB last) ----
echo "Deleting security groups..."
aws ec2 delete-security-group --group-id $DB_SG_ID  --region eu-central-1 --profile admin
aws ec2 delete-security-group --group-id $APP_SG_ID --region eu-central-1 --profile admin
aws ec2 delete-security-group --group-id $WEB_SG_ID --region eu-central-1 --profile admin
aws ec2 delete-security-group --group-id $ELB_SG_ID --region eu-central-1 --profile admin

# ---- Route Table Associations + Route Table ----
echo "Deleting route tables..."
aws ec2 disassociate-route-table --association-id rtbassoc-0c8ccff9d9bea7ebb --region eu-central-1 --profile admin
aws ec2 disassociate-route-table --association-id rtbassoc-09d86718b48a5357d --region eu-central-1 --profile admin
aws ec2 delete-route-table --route-table-id $RT_PUBLIC_ID --region eu-central-1 --profile admin

# ---- Subnets ----
echo "Deleting subnets..."
aws ec2 delete-subnet --subnet-id $WEB_AZ1_ID --region eu-central-1 --profile admin
aws ec2 delete-subnet --subnet-id $WEB_AZ2_ID --region eu-central-1 --profile admin
aws ec2 delete-subnet --subnet-id $APP_AZ1_ID --region eu-central-1 --profile admin
aws ec2 delete-subnet --subnet-id $APP_AZ2_ID --region eu-central-1 --profile admin
aws ec2 delete-subnet --subnet-id $DB_AZ1_ID  --region eu-central-1 --profile admin
aws ec2 delete-subnet --subnet-id $DB_AZ2_ID  --region eu-central-1 --profile admin

# ---- Internet Gateway ----
echo "Deleting internet gateway..."
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region eu-central-1 --profile admin
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region eu-central-1 --profile admin

# ---- VPC ----
echo "Deleting VPC..."
aws ec2 delete-vpc --vpc-id $VPC_ID --region eu-central-1 --profile admin

echo "Done — all cli-3tier resources deleted."
