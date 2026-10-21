variable "name_prefix" {
  description = "Prefix for resources"
  type        = string
}

variable "db_credentials_secret_arn" {
  description = "ARN of Secrets Manager secret for DB"
  type        = string
}

variable "ssm_parameter_arns" {
  description = "List of SSM Parameter ARNs task needs to read"
  type        = list(string)
}
