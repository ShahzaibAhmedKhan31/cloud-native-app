output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "alb_sg_id" {
  value = module.security_groups.alb_sg_id
}

output "ecs_sg_id" {
  value = module.security_groups.ecs_sg_id
}

output "rds_sg_id" {
  value = module.security_groups.rds_sg_id
}

# ============================================================
# ECR outputs
# ============================================================
output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecr_repository_name" {
  value = module.ecr.repository_name
}

# ============================================================
# RDS outputs
# ============================================================
output "rds_endpoint" {
  value     = module.rds.db_instance_endpoint
  sensitive = true
}

output "db_credentials_secret_arn" {
  value = module.rds.db_credentials_secret_arn
}

output "db_credentials_secret_name" {
  value = module.rds.db_credentials_secret_name
}



# ============================================================
# ALB & Application URL
# ============================================================
output "alb_dns_name" {
  description = "ALB Public DNS — Access application here"
  value       = module.alb.alb_dns_name
}

output "application_url" {
  description = "Application Web URL"
  value       = "http://${module.alb.alb_dns_name}"
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "github_access_key_id" {
  value = module.github_oidc.access_key_id
}

output "github_secret_access_key" {
  value     = module.github_oidc.secret_access_key
  sensitive = true
}

output "route53_nameservers" {
  description = "COPY THESE 4 NAMESERVERS TO HOSTINGER"
  value       = var.domain_name != "" ? module.dns_acm[0].name_servers : []
}

output "https_application_url" {
  description = "Secure HTTPS Application URL"
  value       = var.domain_name != "" ? "https://${module.dns_acm[0].fqdn}" : "N/A"
}

output "cloudwatch_dashboard_name" {
  description = "Name of CloudWatch Dashboard"
  value       = module.observability.dashboard_name
}

output "sns_alerts_topic_arn" {
  description = "ARN of SNS Alerts Topic"
  value       = module.observability.sns_topic_arn
}
