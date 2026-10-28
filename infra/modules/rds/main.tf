# ============================================================
# Random password for DB master user
# ============================================================
resource "random_password" "db_password" {
  length  = 24
  special = true
  # Avoid characters RDS doesn't accept in passwords
  override_special = "!#$%&*()-_=+[]{}<>?"
}

# ============================================================
# Secrets Manager — store DB credentials
# ============================================================
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.name_prefix}-db-credentials"
  description             = "RDS master credentials for ${var.name_prefix}"
  recovery_window_in_days = 0 # 0 = immediate delete; use 7+ in production
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
  })
}

# ============================================================
# DB Subnet Group — tells RDS which subnets it can live in
# ============================================================
resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.name_prefix}-db-subnet-group"
  }
}

# ============================================================
# DB Parameter Group — tune Postgres config (optional)
# ============================================================
resource "aws_db_parameter_group" "this" {
  name   = "${var.name_prefix}-pg16"
  family = "postgres16"

  parameter {
    name  = "log_statement"
    value = "none" # dev: 'none'; prod/debug: 'all' or 'mod'
  }

  tags = {
    Name = "${var.name_prefix}-pg16"
  }
}

# ============================================================
# RDS PostgreSQL instance
# ============================================================
resource "aws_db_instance" "this" {
  identifier     = "${var.name_prefix}-postgres"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result
  port     = 5432

  vpc_security_group_ids = [var.db_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.this.name
  parameter_group_name   = aws_db_parameter_group.this.name

  multi_az                = var.multi_az
  publicly_accessible     = false
  backup_retention_period = var.backup_retention_days
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name_prefix}-final-snapshot-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  deletion_protection       = var.deletion_protection

  performance_insights_enabled    = var.performance_insights_enabled
  enabled_cloudwatch_logs_exports = ["postgresql"]

  apply_immediately = true # dev: true; prod: false (schedule changes)

  tags = {
    Name = "${var.name_prefix}-postgres"
  }

  lifecycle {
    ignore_changes = [final_snapshot_identifier]
  }
}
