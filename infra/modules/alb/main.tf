# ============================================================
# Application Load Balancer
# ============================================================
resource "aws_lb" "this" {
  name               = "${var.name_prefix}-alb"
  internal           = false   # Public internet facing
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "${var.name_prefix}-alb"
  }
}

# ============================================================
# Target Group (IP target type for ECS Fargate)
# ============================================================
resource "aws_lb_target_group" "this" {
  name        = "${var.name_prefix}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"   # Fargate requires 'ip' mode

  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30   # drained connections timeout

  tags = {
    Name = "${var.name_prefix}-tg"
  }
}

# ============================================================
# HTTP Listener (Port 80 -> Target Group)
# ============================================================
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
