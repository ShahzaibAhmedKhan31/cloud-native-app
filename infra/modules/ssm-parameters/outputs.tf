output "app_env_arn" {
  value = aws_ssm_parameter.app_env.arn
}

output "db_host_arn" {
  value = aws_ssm_parameter.db_host.arn
}

output "db_port_arn" {
  value = aws_ssm_parameter.db_port.arn
}

output "db_name_arn" {
  value = aws_ssm_parameter.db_name.arn
}
