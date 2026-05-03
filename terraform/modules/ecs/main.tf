# ── Cluster ───────────────────────────────────────────────────────────────────
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"

  tags = {
    Name        = "${var.project_name}-cluster"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ── CloudWatch Log Group ──────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# ── Task Definition ───────────────────────────────────────────────────────────
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn

  container_definitions = jsonencode([
    {
      name      = var.project_name
      image     = "${var.ecr_repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = var.app_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = var.environment
        },
        {
          name  = "PORT"
          value = tostring(var.app_port)
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# ── Fargate Service ───────────────────────────────────────────────────────────
resource "aws_ecs_service" "this" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.project_name
    container_port   = var.app_port
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}
