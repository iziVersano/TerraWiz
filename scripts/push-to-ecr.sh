#!/bin/bash
# push-to-ecr.sh
# Builds the prod Docker image and pushes it to AWS ECR.
# Run this from the project root: ./scripts/push-to-ecr.sh

set -e  # exit immediately if any command fails

AWS_REGION="us-east-1"
AWS_PROFILE="admin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TF_DIR="$PROJECT_ROOT/terraform"
APP_DIR="$PROJECT_ROOT/app"

echo "==> Getting ECR repository URL from Terraform output..."
ECR_URL=$(terraform -chdir="$TF_DIR" output -raw ecr_repository_url)

if [[ -z "$ECR_URL" ]]; then
  echo "ERROR: Could not get ECR URL. Have you run terraform apply yet?"
  exit 1
fi

echo "    ECR URL: $ECR_URL"

echo ""
echo "==> Building prod Docker image..."
docker build --target prod -t terrawiz:prod "$APP_DIR"

echo ""
echo "==> Tagging image for ECR..."
docker tag terrawiz:prod "$ECR_URL:latest"

echo ""
echo "==> Authenticating Docker to ECR..."
aws ecr get-login-password --region "$AWS_REGION" --profile "$AWS_PROFILE" \
  | docker login --username AWS --password-stdin "$ECR_URL"

echo ""
echo "==> Pushing image to ECR..."
docker push "$ECR_URL:latest"

echo ""
echo "Done! Image pushed to: $ECR_URL:latest"
echo "ECS Fargate will pull this image when the service starts."
