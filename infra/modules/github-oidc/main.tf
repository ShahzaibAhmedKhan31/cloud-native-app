# ============================================================
# Fetch Current AWS Account ID & Region
# ============================================================
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================================
# GitHub OIDC Identity Provider
# ============================================================
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a2a851502f7501a357597f80f128c7dd36b4"]
}

# ============================================================
# IAM Role Assumed by GitHub Actions (Strict Trust Policy)
# ============================================================
resource "aws_iam_role" "github_actions" {
  name = "${var.name_prefix}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          # 🔒 SECURITY LOCK 1: Restrict ONLY to this specific GitHub repo and branches/PRs
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_org_or_user}/${var.github_repo}:ref:refs/heads/main",
              "repo:${var.github_org_or_user}/${var.github_repo}:pull_request"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-github-actions-role"
  }
}

# ============================================================
# 🔒 SECURITY LOCK 2: Scoped Least-Privilege IAM Policy
# ============================================================
resource "aws_iam_role_policy" "github_actions_scoped_policy" {
  name = "${var.name_prefix}-github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1. S3 & DynamoDB — Terraform State Management
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning"
        ]
        Resource = [
          "arn:aws:s3:::cloud-native-app-tfstate-*",
          "arn:aws:s3:::cloud-native-app-tfstate-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/cloud-native-app-tflock"
      },

      # 2. ECR — Container Push & Pull
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:ListImages"
        ]
        Resource = "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${var.name_prefix}*"
      },

      # 3. ECS — Service Updates & Task Definition Management
      {
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DeregisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "ecs:DescribeClusters",
          "ecs:CreateCluster",
          "ecs:CreateService",
          "ecs:DeleteService",
          "ecs:DeleteCluster"
        ]
        Resource = "*"
      },

      # 4. IAM PassRole & Role Management for Project Roles
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.name_prefix}-*"
      },

      # 5. Infrastructure Management Scope (EC2, ALB, RDS, SecretsManager, CloudWatch, SSM)
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticloadbalancing:*",
          "rds:*",
          "secretsmanager:*",
          "ssm:*",
          "logs:*",
          "cloudwatch:*",
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "*"
      }
    ]
  })
}