#!/bin/bash

# Build and push file_scanner Docker image to ECR
# Usage: ./scripts/build-file-scanner.sh [region] [account-id] [tag]

set -e

# Default values
REGION=${1:-us-east-1}
ACCOUNT_ID=${2:-445567085614}
TAG=${3:-latest}

# ECR repository details
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
REPOSITORY_NAME="tnt-pipeline-file-scanner"
IMAGE_URI="${ECR_REGISTRY}/${REPOSITORY_NAME}:${TAG}"

echo "🏗️  Building file_scanner Docker image..."
echo "   Registry: ${ECR_REGISTRY}"
echo "   Repository: ${REPOSITORY_NAME}"
echo "   Tag: ${TAG}"
echo ""

# Build the image for Linux ARM64 (ECS Fargate ARM compatibility)
echo "📦 Building file_scanner release image for Linux ARM64..."
docker build --platform linux/arm64 -f Dockerfile.file_scanner -t "${REPOSITORY_NAME}:${TAG}" .

# Tag for ECR
echo "🏷️  Tagging image for ECR..."
docker tag "${REPOSITORY_NAME}:${TAG}" "${IMAGE_URI}"

# Login to ECR
echo "🔐 Logging in to ECR..."
aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

# Create repository if it doesn't exist
echo "🗂️  Ensuring ECR repository exists..."
aws ecr describe-repositories --repository-names "${REPOSITORY_NAME}" --region "${REGION}" 2>/dev/null || {
    echo "   Creating repository ${REPOSITORY_NAME}..."
    aws ecr create-repository --repository-name "${REPOSITORY_NAME}" --region "${REGION}"
}

# Push the image
echo "⬆️  Pushing image to ECR..."
docker push "${IMAGE_URI}"

echo ""
echo "✅ Successfully pushed file_scanner image to ECR!"
echo "   Image URI: ${IMAGE_URI}"
echo ""
echo "📋 Next steps:"
echo "   1. Update ECS task definition with this image URI:"
echo "      ${IMAGE_URI}"
echo "   2. Deploy infrastructure: cd infrastructure/envs/prod && terraform apply"
echo "   3. Test file scanner: aws ecs run-task --cluster etl-cluster-prod --task-definition etl-cluster-prod-file-scanner"