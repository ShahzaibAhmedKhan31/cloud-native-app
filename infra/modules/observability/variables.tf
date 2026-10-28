variable "name_prefix" {
  description = "Prefix for resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
  default     = ""
}

variable "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS Service"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB (used in CloudWatch dimensions)"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the Target Group (used in CloudWatch dimensions)"
  type        = string
}
