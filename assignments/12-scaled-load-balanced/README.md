# Issue #12 — Set up a scaled and load-balanced application

Implements the AWS tutorial "Set up a scaled and load-balanced application" using Terraform instead of the AWS Console.

## Architecture

```
Internet / Users
      |
      v
Internet Gateway
      |
      v
Application Load Balancer  (port 80, public)
      |
      v
Target Group  (instance type, health check GET /)
      |
      v
Auto Scaling Group  (min=2, max=4, desired=2)
      |
      +--> EC2 instance  (us-east-1a)
      +--> EC2 instance  (us-east-1b)
```

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with profile `admin`
- AWS region: `us-east-1`

## Deploy

```bash
cd assignments/12-scaled-load-balanced

terraform init
terraform validate
terraform plan
terraform apply
```

After apply, note the `alb_dns_name` output.

## Step 3 — Verify the Load Balancer is attached

**Check the ASG exists and has the launch template attached:**

```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names terrawiz-12-asg \
  --region us-east-1 --profile admin \
  --query 'AutoScalingGroups[0].{Name:AutoScalingGroupName,LT:LaunchTemplate,TG:TargetGroupARNs,Instances:Instances}'
```

**Check EC2 instances launched by the ASG:**

```bash
aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=terrawiz-12-asg" \
            "Name=instance-state-name,Values=running" \
  --region us-east-1 --profile admin \
  --query 'Reservations[].Instances[].[InstanceId,Placement.AvailabilityZone,State.Name]' \
  --output table
```

**Check Target Group health:**

```bash
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw target_group_arn) \
  --region us-east-1 --profile admin \
  --query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State]' \
  --output table
```

Wait until all targets show `healthy` (typically 1–2 minutes after apply).

**Open the app in a browser:**

```bash
echo "http://$(terraform output -raw alb_dns_name)"
```

Refresh several times — the Instance ID and Availability Zone will alternate between the two instances, confirming the ALB is load-balancing across both.

## Step 4 — Test Auto Scaling self-healing

**Terminate one instance manually:**

```bash
# Get an instance ID from the ASG
INSTANCE_ID=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names terrawiz-12-asg \
  --region us-east-1 --profile admin \
  --query 'AutoScalingGroups[0].Instances[0].InstanceId' \
  --output text)

echo "Terminating: $INSTANCE_ID"

aws ec2 terminate-instances \
  --instance-ids "$INSTANCE_ID" \
  --region us-east-1 --profile admin
```

**Watch the ASG detect and replace the instance:**

```bash
watch -n 5 'aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names terrawiz-12-asg \
  --region us-east-1 --profile admin \
  --query "AutoScalingGroups[0].Instances[*].[InstanceId,LifecycleState,HealthStatus]" \
  --output table'
```

Expected sequence:
1. Terminated instance disappears from the ASG.
2. A new instance appears with `LifecycleState: Pending`.
3. It transitions to `InService` (within ~2 minutes).
4. Target Group shows the replacement as `healthy`.
5. The ALB continues serving the app throughout — refresh the browser to confirm.

**Confirm the replacement is healthy in the Target Group:**

```bash
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw target_group_arn) \
  --region us-east-1 --profile admin \
  --query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State]' \
  --output table
```

## Step 5 — Clean up

```bash
terraform destroy
```

Confirm with `yes`. This removes all resources created by this assignment.
