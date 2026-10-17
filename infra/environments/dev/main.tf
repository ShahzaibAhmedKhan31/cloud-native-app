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