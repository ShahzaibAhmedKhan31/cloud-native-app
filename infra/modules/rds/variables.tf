variable "name_prefix" {
  description = "Prefix for resources"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for DB subnet group"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group ID for RDS"
  type        = string
}

variable "engine_version" {
  description = "Postgres engine version"
  type        = string
  default     = "16.3"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial storage (GB)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Max storage for auto-scaling (GB)"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "itemsdb"
}

variable "db_username" {
  description = "DB master username"
  type        = string
  default     = "appuser"
}

variable "multi_az" {
  description = "Enable Multi-AZ for HA"
  type        = bool
  default     = false   # dev: false (saves ~$15/mo); prod: true
}

variable "backup_retention_days" {
  description = "Backup retention period (days)"
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy (dev only!)"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Prevent accidental deletion"
  type        = bool
  default     = false   # dev: false; prod: true
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false   # extra cost
}
