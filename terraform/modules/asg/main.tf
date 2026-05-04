# ── AMI data source ───────────────────────────────────────────────────────────
# Resolves to the latest Amazon Linux 2023 x86_64 HVM AMI at apply time.
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── Launch Template ───────────────────────────────────────────────────────────
resource "aws_launch_template" "this" {
  name          = "${var.project_name}-lt"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.security_group_id]
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.project_name}-asg-instance"
      Project     = var.project_name
      Environment = var.environment
    }
  }

  tags = {
    Name        = "${var.project_name}-lt"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ── Auto Scaling Group ────────────────────────────────────────────────────────
resource "aws_autoscaling_group" "this" {
  name                = "${var.project_name}-asg"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 60

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

# ── Running instance IDs ──────────────────────────────────────────────────────
# Returns IDs of instances currently running in this ASG.
# Empty during plan; populated after apply.
data "aws_instances" "asg_instances" {
  depends_on = [aws_autoscaling_group.this]

  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.this.name]
  }

  filter {
    name   = "instance-state-name"
    values = ["running", "pending"]
  }
}
