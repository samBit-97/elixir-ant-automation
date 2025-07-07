#!/bin/bash

# Script to manually run the file_scanner ECS task
# This replaces the Lambda trigger approach with manual execution

set -e

ENVIRONMENT=${1:-prod}
CLUSTER_NAME="etl-cluster-${ENVIRONMENT}"
TASK_DEFINITION="${CLUSTER_NAME}-file-scanner"
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=*public*" --query 'Subnets[*].SubnetId' --output text | tr '\t' ',')
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=etl-security-group" --query 'SecurityGroups[0].GroupId' --output text)

echo "Starting file_scanner ECS task..."
echo "Environment: ${ENVIRONMENT}"
echo "Cluster: ${CLUSTER_NAME}"
echo "Task Definition: ${TASK_DEFINITION}"

# Run the ECS task
TASK_ARN=$(aws ecs run-task \
  --cluster "${CLUSTER_NAME}" \
  --task-definition "${TASK_DEFINITION}" \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_IDS}],securityGroups=[${SECURITY_GROUP_ID}],assignPublicIp=ENABLED}" \
  --query 'tasks[0].taskArn' \
  --output text)

echo "Task started with ARN: ${TASK_ARN}"

# Wait for task to complete
echo "Waiting for task to complete..."
aws ecs wait tasks-stopped --cluster "${CLUSTER_NAME}" --tasks "${TASK_ARN}"

# Get task exit code
EXIT_CODE=$(aws ecs describe-tasks \
  --cluster "${CLUSTER_NAME}" \
  --tasks "${TASK_ARN}" \
  --query 'tasks[0].containers[0].exitCode' \
  --output text)

echo "Task completed with exit code: ${EXIT_CODE}"

# Show logs
echo "Recent logs:"
aws logs tail "/ecs/file-scanner" --since 10m

if [ "${EXIT_CODE}" == "0" ]; then
  echo "✅ File scanner completed successfully"
else
  echo "❌ File scanner failed with exit code: ${EXIT_CODE}"
  exit 1
fi