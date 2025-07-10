#!/bin/bash

# Start ETL pipeline task (not service)
# Usage: ./scripts/start-etl-pipeline-task.sh [count]

set -e

# Default values
COUNT=${1:-1}
CLUSTER_NAME="etl-cluster-prod"
TASK_DEFINITION="etl-cluster-prod-etl-worker"
REGION="us-east-1"

echo "🚀 Starting ETL pipeline task..."
echo "   Cluster: ${CLUSTER_NAME}"
echo "   Task Definition: ${TASK_DEFINITION}"
echo "   Count: ${COUNT}"
echo "   Region: ${REGION}"
echo ""

# Get subnet and security group from terraform state
echo "📋 Getting network configuration..."

# Change to terraform directory
TERRAFORM_DIR="infrastructure/envs/prod"
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "❌ Terraform directory not found: $TERRAFORM_DIR"
    echo "💡 Please run this script from the project root directory"
    exit 1
fi

cd "$TERRAFORM_DIR"

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ]; then
    echo "❌ Terraform state not found. Please run 'terraform apply' first."
    exit 1
fi

# Get subnet ID (try multiple possible output names)
SUBNET_ID=$(terraform output -raw private_subnet_id 2>/dev/null || terraform output -raw subnet_id 2>/dev/null || terraform output -raw subnet_ids 2>/dev/null | head -1 || echo "")
if [ -z "$SUBNET_ID" ]; then
    echo "❌ Could not get subnet ID from terraform output"
    echo "📋 Available outputs:"
    terraform output
    exit 1
fi
echo "   Subnet ID: ${SUBNET_ID}"

# Get security group ID
SECURITY_GROUP_ID=$(terraform output -raw ecs_security_group_id 2>/dev/null || terraform output -raw fargate_security_group_id 2>/dev/null || terraform output -raw security_group_id 2>/dev/null || echo "")
if [ -z "$SECURITY_GROUP_ID" ]; then
    echo "❌ Could not get security group ID from terraform output"
    echo "📋 Available outputs:"
    terraform output
    exit 1
fi
echo "   Security Group ID: ${SECURITY_GROUP_ID}"

cd - > /dev/null

# Verify cluster exists
echo ""
echo "📋 Verifying cluster exists..."
aws ecs describe-clusters --clusters ${CLUSTER_NAME} --region ${REGION} >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Cluster ${CLUSTER_NAME} not found in region ${REGION}"
    echo "📋 Available clusters:"
    aws ecs list-clusters --region ${REGION} --query 'clusterArns' --output table
    exit 1
fi

# Verify task definition exists
echo "📋 Verifying task definition exists..."
aws ecs describe-task-definition --task-definition ${TASK_DEFINITION} --region ${REGION} >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Task definition ${TASK_DEFINITION} not found"
    echo "📋 Available task definitions:"
    aws ecs list-task-definitions --region ${REGION} --query 'taskDefinitionArns' --output table
    exit 1
fi

echo ""
echo "⏳ Starting ${COUNT} ETL pipeline task(s)..."

# Start the task(s)
TASK_ARNS=()
for i in $(seq 1 $COUNT); do
    echo "Starting task ${i}/${COUNT}..."
    
    TASK_ARN=$(aws ecs run-task \
        --cluster ${CLUSTER_NAME} \
        --task-definition ${TASK_DEFINITION} \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_ID}],securityGroups=[${SECURITY_GROUP_ID}],assignPublicIp=ENABLED}" \
        --region ${REGION} \
        --query 'tasks[0].taskArn' \
        --output text 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$TASK_ARN" != "None" ] && [ -n "$TASK_ARN" ]; then
        echo "✅ Task ${i} started successfully!"
        echo "   Task ARN: ${TASK_ARN}"
        TASK_ARNS+=("$TASK_ARN")
    else
        echo "❌ Failed to start task ${i}!"
        echo "🔍 Checking for errors..."
        
        # Try to get more detailed error information
        aws ecs run-task \
            --cluster ${CLUSTER_NAME} \
            --task-definition ${TASK_DEFINITION} \
            --launch-type FARGATE \
            --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_ID}],securityGroups=[${SECURITY_GROUP_ID}],assignPublicIp=ENABLED}" \
            --region ${REGION} \
            --query 'failures' \
            --output table
        exit 1
    fi
    
    echo ""
done

echo "✅ All ETL pipeline tasks started successfully!"
echo ""
echo "📋 Task ARNs:"
for arn in "${TASK_ARNS[@]}"; do
    echo "   • $arn"
done

echo ""
echo "📋 Monitoring commands:"
echo "   • View logs: aws logs tail /ecs/etl-worker --follow --region ${REGION}"
echo "   • List tasks: aws ecs list-tasks --cluster ${CLUSTER_NAME} --region ${REGION}"
echo "   • Describe tasks: aws ecs describe-tasks --cluster ${CLUSTER_NAME} --tasks [task-arn] --region ${REGION}"
echo ""
echo "🔧 Management commands:"
echo "   • Stop task: aws ecs stop-task --cluster ${CLUSTER_NAME} --task [task-arn] --region ${REGION}"
echo "   • Start more tasks: ./infrastructure/scripts/start-etl-pipeline-task.sh [count]"
echo "   • Check task status: aws ecs describe-tasks --cluster ${CLUSTER_NAME} --tasks ${TASK_ARNS[0]} --region ${REGION}"