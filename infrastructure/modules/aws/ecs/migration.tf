# Database Migration via Terraform
# Automatically runs migrations before cluster services start

# Null resource to run migration task
resource "null_resource" "db_migration" {
  # Triggers - run migration when these change
  triggers = {
    cluster_id              = aws_ecs_cluster.this.id
    task_definition_arn     = aws_ecs_task_definition.db_migration.arn
    rds_hostname           = var.rds_hostname
    always_run             = timestamp() # Run on every apply if needed
  }

  # Run database migration
  provisioner "local-exec" {
    command = <<-EOT
      echo "🔧 Running database migration for TNT Pipeline..."
      
      # Wait a bit for task definition to be ready
      sleep 5
      
      # Run the migration task
      TASK_ARN=$(aws ecs run-task \
        --cluster ${aws_ecs_cluster.this.name} \
        --task-definition ${aws_ecs_task_definition.db_migration.arn} \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[${var.subnet_ids[0]}],securityGroups=[${aws_security_group.cluster.id}],assignPublicIp=ENABLED}" \
        --query 'tasks[0].taskArn' \
        --output text)
      
      if [ -z "$TASK_ARN" ]; then
        echo "❌ Failed to start migration task"
        exit 1
      fi
      
      echo "✅ Migration task started: $TASK_ARN"
      echo "⏳ Waiting for migration to complete..."
      
      # Wait for task to complete (timeout after 10 minutes)
      TIMEOUT=600
      ELAPSED=0
      
      while [ $ELAPSED -lt $TIMEOUT ]; do
        TASK_STATUS=$(aws ecs describe-tasks \
          --cluster ${aws_ecs_cluster.this.name} \
          --tasks $TASK_ARN \
          --query 'tasks[0].lastStatus' \
          --output text)
        
        case $TASK_STATUS in
          "STOPPED")
            EXIT_CODE=$(aws ecs describe-tasks \
              --cluster ${aws_ecs_cluster.this.name} \
              --tasks $TASK_ARN \
              --query 'tasks[0].containers[0].exitCode' \
              --output text)
            
            if [ "$EXIT_CODE" = "0" ]; then
              echo "✅ Database migration completed successfully!"
              exit 0
            else
              echo "❌ Migration failed with exit code: $EXIT_CODE"
              exit 1
            fi
            ;;
          "RUNNING")
            echo "🔄 Migration is running... ($ELAPSED seconds elapsed)"
            ;;
        esac
        
        sleep 10
        ELAPSED=$((ELAPSED + 10))
      done
      
      echo "❌ Migration timed out after $TIMEOUT seconds"
      exit 1
    EOT
  }

  # Dependencies - run after infrastructure is ready but before services
  depends_on = [
    aws_ecs_cluster.this,
    aws_ecs_task_definition.db_migration,
    aws_security_group.cluster,
    aws_cloudwatch_log_group.db_migration
  ]
}

# Output migration status
output "migration_status" {
  description = "Database migration completion status"
  value       = "Migration completed at ${null_resource.db_migration.id}"
  depends_on  = [null_resource.db_migration]
}