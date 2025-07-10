#!/bin/bash

# Production deployment script for TntPipeline
# Handles two-stage deployment to avoid circular dependency

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROD_DIR="${SCRIPT_DIR}/../envs/prod"

echo "🚀 TntPipeline Production Deployment"
echo "===================================="
echo ""

# Check if we're in the right directory
if [ ! -f "${PROD_DIR}/main.tf" ]; then
    echo "❌ Error: Cannot find production terraform files"
    echo "   Expected: ${PROD_DIR}/main.tf"
    exit 1
fi

# Change to production directory
cd "${PROD_DIR}"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ Error: terraform.tfvars not found"
    echo "   Please copy and configure terraform.tfvars.template first:"
    echo "   cp terraform.tfvars.template terraform.tfvars"
    echo "   # Edit terraform.tfvars with your actual values"
    exit 1
fi

echo "📋 Stage 1: Initial Infrastructure Deployment"
echo "--------------------------------------------"
echo "• Deploying ALB, Go API service, and ETL pipeline"
echo "• Using placeholder API URL for ETL pipeline"
echo ""

# Initialize terraform if needed
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing Terraform..."
    terraform init
fi

# Plan and apply
echo "📊 Planning deployment..."
terraform plan -out=tfplan

echo "🚀 Applying infrastructure..."
terraform apply tfplan

echo ""
echo "✅ Stage 1 Complete!"
echo ""

# Get the ALB DNS name
ALB_DNS=$(terraform output -raw go_api_alb_dns_name)
API_URL=$(terraform output -raw go_api_url)

echo "📋 Stage 2: Update API URL Configuration"
echo "----------------------------------------"
echo "• ALB DNS Name: ${ALB_DNS}"
echo "• API URL: ${API_URL}"
echo ""

echo ""
echo "🔄 Applying updated configuration..."
terraform plan -out=tfplan-stage2
terraform apply tfplan-stage2

echo ""
echo "🎉 Deployment Complete!"
echo "======================"
echo ""
echo "📊 Infrastructure Summary:"
echo "• ALB DNS Name: ${ALB_DNS}"
echo "• API URL: ${API_URL}"
echo "• ETL Pipeline: Configured with API URL"
echo ""
echo "📋 Next Steps:"
echo "1. Test Go API: curl ${API_URL}/health"
echo "2. Build ETL pipeline image: ./infrastructure/scripts/build-etl-pipeline.sh"
echo "3. Test ETL pipeline: aws ecs run-task --cluster etl-cluster-prod --task-definition etl-cluster-prod-etl-worker"
echo ""
echo "🔗 Useful Commands:"
echo "• View ECS services: aws ecs list-services --cluster etl-cluster-prod"
echo "• Check API logs: aws logs tail /ecs/go-api --follow"
echo "• Check ETL logs: aws logs tail /ecs/etl-worker --follow"
