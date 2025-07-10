#!/bin/bash

# Run database migrations on production RDS
# Usage: ./scripts/migrate-production.sh

set -e

echo "🔧 Running database migrations on production RDS..."

# Set environment variables for production migration
export DB_USERNAME=${USERNAME}
export DB_PASSWORD=${PASSWORD}
export RDS_HOSTNAME=${HOST}
export DB_NAME=etl_rds
export DB_PORT=${PORT}
export MIX_ENV=prod

echo "📋 Migration Configuration:"
echo "   Database: ${DB_NAME}"
echo "   Host: ${RDS_HOSTNAME}"
echo "   User: ${DB_USERNAME}"
echo "   Environment: ${MIX_ENV}"
echo ""

# Run migrations
echo "⏳ Running migrations..."
mix ecto.migrate -r Common.Repo

# Verify migration success
echo ""
echo "✅ Verifying migration success..."
echo "📋 Checking if oban_jobs table exists..."

PGPASSWORD=$DB_PASSWORD psql -h ${RDS_HOSTNAME} -U ${DB_USERNAME} -d ${DB_NAME} -c "\dt oban_jobs"

if [ $? -eq 0 ]; then
    echo "✅ Migration completed successfully!"
    echo "📋 Database tables:"
    PGPASSWORD=$DB_PASSWORD psql -h ${RDS_HOSTNAME} -U ${DB_USERNAME} -d ${DB_NAME} -c "\dt"
else
    echo "❌ Migration verification failed!"
    exit 1
fi

echo ""
echo "🎉 Production database migration completed!"
echo "📋 Next steps:"
echo "   1. Run ETL pipeline: ./scripts/start-etl-pipeline.sh [desired_count]"
echo "   2. Monitor logs: aws logs tail /ecs/etl-worker --follow"
