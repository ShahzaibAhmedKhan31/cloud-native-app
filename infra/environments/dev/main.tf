locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Fetch available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================================
# VPC + Networking
# ============================================================
module "vpc" {
  source = "../../modules/vpc"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = slice(data.aws_availability_zones.available.names, 0, 2)

  single_nat_gateway = true # cost-saving for dev
  enable_flow_logs   = true
}

# ============================================================
# Security Groups
# ============================================================
module "security_groups" {
  source = "../../modules/security-groups"

  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id
  app_port    = var.app_port
}



# ============================================================
# ECR Repository (for Docker images)
# ============================================================
module "ecr" {
  source = "../../modules/ecr"

  repository_name = local.name_prefix
  max_image_count = 10
}

# ============================================================
# RDS PostgreSQL
# ============================================================
module "rds" {
  source = "../../modules/rds"

  name_prefix          = local.name_prefix
  private_subnet_ids   = module.vpc.private_subnet_ids
  db_security_group_id = module.security_groups.rds_sg_id

  engine_version    = "16.9"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name     = "itemsdb"
  db_username = "appuser"

  multi_az              = false   # dev
  backup_retention_days = 7
  skip_final_snapshot   = true    # dev
  deletion_protection   = false   # dev
}

# ============================================================
# SSM Parameter Store (non-sensitive config)
# ============================================================
module "ssm_parameters" {
  source = "../../modules/ssm-parameters"

  name_prefix = local.name_prefix
  environment = var.environment

  db_host = module.rds.db_instance_address
  db_port = module.rds.db_instance_port
  db_name = module.rds.db_name
}


# ============================================================
# IAM Roles for ECS
# ============================================================
module "iam" {
  source = "../../modules/iam"

  name_prefix               = local.name_prefix
  db_credentials_secret_arn = module.rds.db_credentials_secret_arn
  ssm_parameter_arns = [
    module.ssm_parameters.app_env_arn,
    module.ssm_parameters.db_host_arn,
    module.ssm_parameters.db_port_arn,
    module.ssm_parameters.db_name_arn
  ]
}

# ============================================================
# Application Load Balancer
# ============================================================
module "alb" {
  source = "../../modules/alb"

  name_prefix           = local.name_prefix
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_sg_id
  app_port              = var.app_port
  health_check_path     = "/health"
}

# ============================================================
# ECS Cluster, Task Definition & Service
# ============================================================
module "ecs" {
  source = "../../modules/ecs"

  name_prefix           = local.name_prefix
  aws_region            = var.aws_region
  environment           = var.environment
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = module.security_groups.ecs_sg_id
  ecr_repository_url    = module.ecr.repository_url

  app_port           = var.app_port
  desired_count      = 2
  execution_role_arn = module.iam.ecs_execution_role_arn
  task_role_arn      = module.iam.ecs_task_role_arn
  target_group_arn   = module.alb.target_group_arn
  alb_listener_arn   = module.alb.alb_arn

  db_host                   = module.rds.db_instance_address
  db_port                   = module.rds.db_instance_port
  db_name                   = module.rds.db_name
  db_user                   = "appuser"
  db_credentials_secret_arn = module.rds.db_credentials_secret_arn
}


# ============================================================
# GitHub Actions OIDC Authentication
# ============================================================
module "github_oidc" {
  source = "../../modules/github-oidc"

  name_prefix        = local.name_prefix
  github_org_or_user = var.github_username
  github_repo        = "cloud-native-app"
}