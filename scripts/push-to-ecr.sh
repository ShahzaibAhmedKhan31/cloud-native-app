#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------
# Build & push the app image to ECR
# -----------------------------------------
# Usage:
#   ./scripts/push-to-ecr.sh
#
# Requirements:
#   - AWS CLI configured with the right profile
#   - Terraform state applied (dev environment)
# -----------------------------------------

cd "$(dirname "$0")/.."

AWS_REGION=${AWS_REGION:-us-east-1}

echo "📦 Reading ECR URL from Terraform..."
ECR_URL=$(cd infra/environments/dev && terraform output -raw ecr_repository_url)
echo "   ECR: $ECR_URL"

GIT_SHA=$(git rev-parse --short HEAD)
echo "   Git SHA: $GIT_SHA"

echo "🔑 Logging into ECR..."
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$ECR_URL"

echo "🔨 Building image for linux/amd64..."
docker build --platform linux/amd64 -t cloud-native-app:latest ./app

echo "🏷️  Tagging..."
docker tag cloud-native-app:latest "$ECR_URL:latest"
docker tag cloud-native-app:latest "$ECR_URL:$GIT_SHA"

echo "⬆️  Pushing..."
docker push "$ECR_URL:latest"
docker push "$ECR_URL:$GIT_SHA"

echo "✅ Done!"
echo "   Image: $ECR_URL:$GIT_SHA"