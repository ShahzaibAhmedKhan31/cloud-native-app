variable "name_prefix" {
  description = "Prefix used for resource names"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "List of AZs — must match length of subnet CIDR lists"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "If true, use one NAT GW for all private subnets (cheaper, lower HA)"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "If true, enable VPC flow logs"
  type        = bool
  default     = true
}