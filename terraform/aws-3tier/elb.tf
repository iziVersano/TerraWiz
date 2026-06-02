# ============================================================
# elb.tf
# Defines the Elastic Load Balancer (ELB) for the web tier.
# Diagram: the green "ELB – Elastic Load Balancer" box at the top of the VPC.
#
# ⚠️  THIS WILL INCUR CHARGES — DO NOT APPLY
#     Cost: ~$0.018/hr (~$13/month) while running.
#     Free alternative: use the EC2 public IP directly (what we are doing).
#     Create this only when your course covers load balancing.
#
# To apply just this resource when ready:
#   terraform apply -target=aws_lb.main
#   terraform apply -target=aws_lb_listener.http
#   terraform apply -target=aws_lb_target_group.web
# ============================================================

# ------------------------------------------------------------
# TARGET GROUP
# The ELB needs to know WHERE to send traffic — the target group
# is the list of EC2s that will receive requests.
# Health check on / — if EC2 returns 200 it is healthy.
#
# AWS CLI equivalent:
#   aws elbv2 create-target-group \
#     --name 3tier-web-tg \
#     --protocol HTTP --port 80 \
#     --vpc-id <vpc-id> \
#     --target-type instance \
#     --region eu-central-1 --profile admin
# ------------------------------------------------------------

resource "aws_lb_target_group" "web" {
  name     = "${var.project}-web-tg"  # "3tier-web-tg"
  port     = 80                        # forward traffic to port 80 on EC2s
  protocol = "HTTP"                    # HTTP protocol
  vpc_id   = aws_vpc.main.id           # must be in same VPC as the EC2s

  health_check {
    path                = "/"    # check the root path
    protocol            = "HTTP"
    healthy_threshold   = 2      # 2 successful checks = healthy
    unhealthy_threshold = 3      # 3 failed checks = unhealthy
    interval            = 30     # check every 30 seconds
  }

  tags = {
    Name        = "${var.project}-web-tg"
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# APPLICATION LOAD BALANCER
# The actual load balancer — sits in both public web subnets
# so it is highly available across 2 AZs.
#
# AWS CLI equivalent:
#   aws elbv2 create-load-balancer \
#     --name 3tier-alb \
#     --subnets <web-az1-id> <web-az2-id> \
#     --security-groups <elb-sg-id> \
#     --region eu-central-1 --profile admin
# ------------------------------------------------------------

resource "aws_lb" "main" {
  name               = "${var.project}-alb"          # "3tier-alb"
  internal           = false                          # public-facing — not internal
  load_balancer_type = "application"                  # ALB — works at HTTP layer
  security_groups    = [aws_security_group.elb.id]   # only the ELB SG
  subnets            = [                              # must span at least 2 AZs
    aws_subnet.web_az1.id,
    aws_subnet.web_az2.id,
  ]

  tags = {
    Name        = "${var.project}-alb"
    Environment = var.environment
  }
}

# ------------------------------------------------------------
# LISTENER
# Tells the ELB to listen on port 80 and forward to the target group.
# Without a listener the ELB exists but accepts no traffic.
#
# AWS CLI equivalent:
#   aws elbv2 create-listener \
#     --load-balancer-arn <alb-arn> \
#     --protocol HTTP --port 80 \
#     --default-actions Type=forward,TargetGroupArn=<tg-arn> \
#     --region eu-central-1 --profile admin
# ------------------------------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn  # attach to our ALB
  port              = 80               # listen on port 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"                       # forward traffic to target group
    target_group_arn = aws_lb_target_group.web.arn    # send to our web EC2s
  }
}
