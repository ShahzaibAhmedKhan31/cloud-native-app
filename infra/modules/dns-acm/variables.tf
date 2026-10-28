variable "name_prefix" {
  description = "Prefix for resources"
  type        = string
}

variable "domain_name" {
  description = "Your registered domain name from Hostinger (e.g. mydomain.com)"
  type        = string
}

variable "subdomain" {
  description = "Subdomain prefix (e.g. 'app' for app.mydomain.com)"
  type        = string
  default     = "app"
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  type        = string
}

variable "alb_zone_id" {
  description = "Canonical Hosted Zone ID of the ALB"
  type        = string
}