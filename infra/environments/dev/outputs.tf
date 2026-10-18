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