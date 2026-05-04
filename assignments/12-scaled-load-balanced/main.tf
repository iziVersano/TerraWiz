# ── VPC ──────────────────────────────────────────────────────────────────────
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ── Public Subnets ────────────────────────────────────────────────────────────
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.subnet_a_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-subnet-a"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.subnet_b_cidr
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-subnet-b"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ── Internet Gateway ──────────────────────────────────────────────────────────
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${var.project_name}-igw"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ── Public Route Table ────────────────────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name        = "${var.project_name}-rt"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ── ALB Security Group ────────────────────────────────────────────────────────
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP from the internet to the ALB"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ── EC2 Security Group ────────────────────────────────────────────────────────
# Only allows HTTP traffic originating from the ALB, not the open internet.
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allow HTTP from the ALB only"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ec2-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ── Application Load Balancer ─────────────────────────────────────────────────
resource "aws_lb" "this" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name        = "${var.project_name}-alb"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ── Target Group ──────────────────────────────────────────────────────────────
# target_type = "instance" is correct for EC2 ASG (not "ip" which is for Fargate).
resource "aws_lb_target_group" "this" {
  name        = "${var.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.project_name}-tg"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ── ALB Listener ──────────────────────────────────────────────────────────────
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# ── AMI Data Source ───────────────────────────────────────────────────────────
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
    security_groups             = [aws_security_group.ec2.id]
  }

  user_data = filebase64("${path.module}/user_data.sh")

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.project_name}-instance"
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
  vpc_zone_identifier = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.this.arn]

  # ELB health check lets the ALB decide instance health (not just EC2 status).
  health_check_type         = "ELB"
  health_check_grace_period = 120

  tag {
    key                 = "Name"
    value               = "${var.project_name}-instance"
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
