#!/bin/bash

# Build and push ETL pipeline Docker image to ECR
# Usage: ./scripts/build-etl-pipeline.sh [region] [account-id] [tag]

set -e

# Default values
REGION=${1:-us-east-1}
ACCOUNT_ID=${2:-${AWS_ACCOUNT_ID}}
TAG=${3:-latest}

# ECR repository details
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
REPOSITORY_NAME="tnt-pipeline-etl"
IMAGE_URI="${ECR_REGISTRY}/${REPOSITORY_NAME}:${TAG}"

echo "🏗️  Building ETL pipeline Docker image..."
echo "   Registry: ${ECR_REGISTRY}"
echo "   Repository: ${REPOSITORY_NAME}"
echo "   Tag: ${TAG}"
echo ""

# Build the image for Linux ARM64 (ECS Fargate ARM compatibility)
echo "📦 Building ETL pipeline release image for Linux ARM64..."
docker build --platform linux/arm64 -f Dockerfile.etl_pipeline -t "${REPOSITORY_NAME}:${TAG}" .

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
echo "✅ Successfully pushed ETL pipeline image to ECR!"
echo "   Image URI: ${IMAGE_URI}"
echo ""
echo "📋 Next steps:"
echo "   1. Update ECS task definition with this image URI:"
echo "      ${IMAGE_URI}"
echo "   2. Deploy infrastructure: cd infrastructure/envs/prod && terraform apply"
echo "   3. Test ETL worker: aws ecs run-task --cluster etl-cluster-prod --task-definition etl-cluster-prod-etl-worker"