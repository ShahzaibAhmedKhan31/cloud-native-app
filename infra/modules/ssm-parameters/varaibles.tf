variable "name_prefix" {
  description = "Prefix for parameters"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/prod)"
  type        = string
}

variable "db_host" {
  description = "DB hostname"
  type        = string
}

variable "db_port" {
  description = "DB port"
  type        = number
}

variable "db_name" {
  description = "DB name"
  type        = string
}
