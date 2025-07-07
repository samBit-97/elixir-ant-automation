#!/bin/bash

# ETL Workers Scaling Script for Monthly Batch Processing
# Usage: ./scale-etl-workers.sh [up|down|status] [environment]

set -e

ENVIRONMENT=${2:-prod}
CLUSTER_NAME="etl-cluster-${ENVIRONMENT}"
SERVICE_NAME="${CLUSTER_NAME}-etl-workers"

case "$1" in
  "up")
    echo "🚀 Scaling ETL workers UP to 50 for batch processing..."
    aws ecs update-service \
      --cluster "$CLUSTER_NAME" \
      --service "$SERVICE_NAME" \
      --desired-count 50
    
    echo "⏳ Waiting for scaling to complete..."
    aws ecs wait services-stable \
      --cluster "$CLUSTER_NAME" \
      --services "$SERVICE_NAME"
    
    echo "✅ ETL workers scaled to 50. Ready for batch processing!"
    ;;
    
  "down")
    echo "📉 Scaling ETL workers DOWN to 1 for cost optimization..."
    aws ecs update-service \
      --cluster "$CLUSTER_NAME" \
      --service "$SERVICE_NAME" \
      --desired-count 1
    
    echo "⏳ Waiting for scaling to complete..."
    aws ecs wait services-stable \
      --cluster "$CLUSTER_NAME" \
      --services "$SERVICE_NAME"
    
    echo "✅ ETL workers scaled down to 1. Monthly costs optimized!"
    ;;
    
  "status")
    echo "📊 Current ETL workers status:"
    aws ecs describe-services \
      --cluster "$CLUSTER_NAME" \
      --services "$SERVICE_NAME" \
      --query 'services[0].{DesiredCount:desiredCount,RunningCount:runningCount,PendingCount:pendingCount}' \
      --output table
    ;;
    
  *)
    echo "Usage: $0 [up|down|status] [environment]"
    echo ""
    echo "Commands:"
    echo "  up     - Scale to 50 workers for monthly batch processing"
    echo "  down   - Scale to 1 worker for cost optimization"
    echo "  status - Show current worker count"
    echo ""
    echo "Environment: dev|prod (default: prod)"
    echo ""
    echo "Examples:"
    echo "  $0 up prod      # Scale production workers to 50"
    echo "  $0 down prod    # Scale production workers to 1" 
    echo "  $0 status prod  # Check production worker status"
    exit 1
    ;;
esac
