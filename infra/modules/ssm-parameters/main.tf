# ============================================================
# SSM Parameters — non-sensitive app config
# ============================================================
resource "aws_ssm_parameter" "app_env" {
  name  = "/${var.name_prefix}/app/env"
  type  = "String"
  value = var.environment

  tags = {
    Name = "${var.name_prefix}-app-env"
  }
}

resource "aws_ssm_parameter" "db_host" {
  name  = "/${var.name_prefix}/db/host"
  type  = "String"
  value = var.db_host
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/${var.name_prefix}/db/port"
  type  = "String"
  value = tostring(var.db_port)
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/${var.name_prefix}/db/name"
  type  = "String"
  value = var.db_name
}
