# ============================================================
# CloudWatch Log Group for Containers
# ============================================================
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.name_prefix}"
  retention_in_days = 7

  tags = {
    Name = "${var.name_prefix}-container-logs"
  }
}

# ============================================================
# ECS Cluster
# ============================================================
resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"   # dev: disabled to save costs; prod: enabled
  }

  tags = {
    Name = "${var.name_prefix}-cluster"
  }
}

# ============================================================
# ECS Task Definition
# ============================================================
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.name_prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ]

      # Non-sensitive environment variables
      environment = [
        { name = "APP_ENV", value = var.environment },
        { name = "DB_HOST", value = var.db_host },
        { name = "DB_PORT", value = tostring(var.db_port) },
        { name = "DB_NAME", value = var.db_name },
        { name = "DB_USER", value = var.db_user }
      ]

      # Secrets pulled directly from Secrets Manager on task startup
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.db_credentials_secret_arn}:password::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])

  tags = {
    Name = "${var.name_prefix}-task"
  }
}

# ============================================================
# ECS Service
# ============================================================
resource "aws_ecs_service" "this" {
  name            = "${var.name_prefix}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false   # Private subnets use NAT Gateway
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.app_port
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  # Allow task definition changes without service recreate
  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = [var.alb_listener_arn]
}
