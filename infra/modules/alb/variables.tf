variable "name_prefix" {
  description = "Prefix for resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public Subnet IDs for ALB placement"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "app_port" {
  description = "Port application runs on"
  type        = number
  default     = 8000
}

variable "health_check_path" {
  description = "Health check path for target group"
  type        = string
  default     = "/health"
}
