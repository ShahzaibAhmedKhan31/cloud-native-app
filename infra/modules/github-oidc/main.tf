# ============================================================
# Fetch Current AWS Account ID & Region
# ============================================================
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================================
# IAM User for GitHub Actions CI/CD
# ============================================================
resource "aws_iam_user" "github_actions" {
  name = "${var.name_prefix}-github-actions-user"

  tags = {
    Name = "${var.name_prefix}-github-actions-user"
  }
}

# ============================================================
# Access Key for GitHub Actions
# ============================================================
resource "aws_iam_access_key" "github_actions" {
  user = aws_iam_user.github_actions.name
}

# ============================================================
# Scoped Policy Attached to the IAM User
# ============================================================
resource "aws_iam_user_policy" "github_actions_policy" {
  name = "${var.name_prefix}-github-actions-policy"
  user = aws_iam_user.github_actions.name

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

      # 3. ECS — Deployment & Service Updates
      {
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DeregisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "ecs:DescribeClusters"
        ]
        Resource = "*"
      },

      # 4. IAM PassRole
      {
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.name_prefix}-*"
      }
    ]
  })
}