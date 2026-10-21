variable "name_prefix" {
  description = "Prefix for resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private Subnet IDs"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ECS Security Group ID"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR Repository URL"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "container_name" {
  description = "Name of container"
  type        = string
  default     = "app"
}

variable "app_port" {
  description = "Container port"
  type        = number
  default     = 8000
}

variable "fargate_cpu" {
  description = "Fargate CPU units (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "fargate_memory" {
  description = "Fargate Memory in MB (512)"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of container instances"
  type        = number
  default     = 2
}

variable "execution_role_arn" {
  description = "ECS Task Execution Role ARN"
  type        = string
}

variable "task_role_arn" {
  description = "ECS Task Role ARN"
  type        = string
}

variable "target_group_arn" {
  description = "ALB Target Group ARN"
  type        = string
}

variable "alb_listener_arn" {
  description = "ALB Listener ARN (dependency management)"
  type        = string
}

variable "db_host" {
  description = "DB Host"
  type        = string
}

variable "db_port" {
  description = "DB Port"
  type        = number
}

variable "db_name" {
  description = "DB Name"
  type        = string
}

variable "db_user" {
  description = "DB Username"
  type        = string
  default     = "appuser"
}

variable "db_credentials_secret_arn" {
  description = "Secret Manager ARN for DB password"
  type        = string
}
