output "cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "ECS Service Name"
  value       = aws_ecs_service.this.name
}

output "log_group_name" {
  description = "CloudWatch Log Group Name"
  value       = aws_cloudwatch_log_group.ecs.name
}
