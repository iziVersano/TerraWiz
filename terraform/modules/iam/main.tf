# ── Task Execution Role ───────────────────────────────────────────────────────
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ecs-execution-role"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ── Policy Attachment ─────────────────────────────────────────────────────────
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ── S3 Upload Policy ──────────────────────────────────────────────────────────
resource "aws_iam_role_policy" "s3_upload" {
  name = "${var.project_name}-s3-upload-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${var.uploads_bucket_arn}/*"
      }
    ]
  })
}
