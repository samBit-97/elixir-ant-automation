# TntPipeline

## Overview

TntPipeline is a production-ready Elixir umbrella project designed for scalable ETL processing of shipping data. It combines the power of Elixir's fault-tolerant design with AWS cloud services to handle large-scale data processing workflows efficiently.

**Key Capabilities:**

- 🚀 **Scalable AWS Architecture**: ECS Fargate with auto-scaling (0-10 workers)
- 📊 **High Performance**: Processes 20K+ test cases with parallel execution
- 💰 **Cost Optimized**: $2.05 per 1000 files with predictable pricing
- 🔄 **Manual Control**: Admin-controlled batch processing for cost management

## Project Structure

- **apps/etl_pipeline**: Main ETL application with data enrichment, validation, and API integration
- **apps/file_scanner**: S3 file discovery and job enqueueing service
- **apps/common**: Shared utilities, models, database, and AWS integrations

## Key Features

### 🏗️ **Production AWS Architecture**

- **ECS Fargate**: Containerized execution with auto-scaling (0-10 workers)
- **Manual Execution**: Cost-controlled batch processing via admin scripts
- **DynamoDB Integration**: Results storage for real-time dashboard
- **S3 File Processing**: Handles 1000+ files per batch efficiently

### 💻 **Development & Testing**

- 🚀 **Parallel Processing**: Elixir Flow for concurrent data processing
- 📁 **S3 Integration**: Automated file discovery with LocalStack support
- 🔄 **Background Jobs**: Oban-powered job queue for reliable processing
- 🧪 **High Test Coverage**: Comprehensive test suite with 30+ test cases
- 🐳 **Docker Support**: Multi-stage builds for development and production
- ⚙️ **Environment-based Configuration**: Flexible config for dev/test/prod

## Setup Instructions

### Prerequisites

- Elixir 1.18+ and Erlang/OTP 26+
- PostgreSQL 13+
- AWS credentials (or LocalStack for development)

### 1. Clone and Install

```bash
git clone <repository-url>
cd tnt_pipeline
mix deps.get
```

### 2. Environment Configuration

Copy and configure environment variables:
Create .env file with required Environment variables

Key environment variables:

- `API_URL`: Target API endpoint for enrichment
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`: AWS credentials
- `S3_BUCKET`: S3 bucket name for file processing
- `DB_*`: Database connection parameters

### 3. Database Setup

```bash
# Start PostgreSQL (via Docker)
docker-compose up -d postgres

# Create and migrate database
mix ecto.create
mix ecto.migrate
```

### 4. Run Tests

```bash
# Run all tests
mix test

# Run with coverage report
mix test --cover

# Run tests with environment variables loaded
source .env && mix test
```

## Usage

### 🚀 **Production (AWS)**

```bash
# Upload CSV files to S3 bucket
aws s3 cp data/ s3://tnt-pipeline-etl-files-prod/ --recursive

# Run file processing (admin controlled)
./infrastructure/scripts/run_file_scanner.sh prod

# Monitor processing
aws logs tail /ecs/file-scanner --since 10m
aws ecs describe-services --cluster etl-cluster-prod --services etl-worker
```

### 💻 **Development Mode**

```bash
# Start with environment variables
source .env && mix run --no-halt

# Or with specific apps
source .env && mix run --no-halt -e "FileScanner.Scanner.run()"
```

### 📁 **File Scanner Service**

```bash
# Scan all files in S3 bucket
mix file_scanner.run

# Scan with specific prefix
mix file_scanner.run "folder/subfolder"
```

### 🐳 **Docker Deployment**

```bash
# Start full development environment
docker-compose up

# Build production releases
mix release etl_pipeline
mix release file_scanner
```

### Testing with LocalStack

For development, use LocalStack to simulate AWS services:

```bash
# Start LocalStack
docker-compose up localstack

# Create test bucket
aws --endpoint-url=http://localhost:4566 s3 mb s3://tnt-automation-test
```

## Architecture

### 🏗️ **AWS Production Architecture**

```
S3 Bucket → Manual Script → ECS File Scanner → Oban Jobs → Auto-Scaled ETL Workers → DynamoDB
```

**Manual Execution Workflow:**

1. **File Upload**: Upload CSV files to S3 bucket
2. **Manual Trigger**: Run `./infrastructure/scripts/run_file_scanner.sh prod`
3. **File Discovery**: ECS task scans S3 and creates Oban jobs
4. **Auto-Scaling**: ECS service scales ETL workers (0-10 instances)
5. **Processing**: Parallel job execution with results to DynamoDB

### 💻 **Development Architecture**

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  File Scanner   │───▶│   S3/LocalStack  │───▶│  ETL Pipeline   │
│                 │    │                  │    │                 │
│ - Discovers     │    │ - CSV Data       │    │ - Enrichment    │
│ - Enqueues      │    │ - Streaming      │    │ - Validation    │
│ - Schedules     │    │ - Processing     │    │ - API Calls     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                       │
         ▼                        ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Oban Job Queue                             │
│              (PostgreSQL-backed)                               │
└─────────────────────────────────────────────────────────────────┘
```

## Test Coverage

Current test coverage:

- **Common**: Comprehensive coverage for utilities, S3, HTTP clients
- **ETL Pipeline**: 60%+ coverage with full integration tests
- **File Scanner**: High coverage for core scanning logic

Run coverage reports:

```bash
mix test --cover
# View detailed HTML reports in cover/ directory
```

## Configuration

### Test Environment

All test configuration is centralized in `config/test.exs` including:

- Mock S3 settings
- Test database configuration
- API endpoints and credentials
- Oban test setup

### Production Environment

Environment-driven configuration supports:

- AWS credentials and regions
- Database connection pooling
- API rate limiting and timeouts
- Logging levels and formatters

## 🏗️ **AWS Infrastructure Deployment**

### Infrastructure Setup

```bash
# Deploy to production
cd infrastructure/envs/prod
terraform init
terraform plan
terraform apply

# Deploy to development
cd infrastructure/envs/dev
terraform init && terraform apply
```

### Docker Image Build & Push

```bash
# Build and push file scanner image
docker build -f Dockerfile.file_scanner -t tnt-pipeline-file-scanner .
docker tag tnt-pipeline-file-scanner:latest ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/tnt-pipeline-file-scanner:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/tnt-pipeline-file-scanner:latest

# Build and push ETL pipeline image
docker build -f Dockerfile.etl_pipeline -t tnt-pipeline-etl .
docker tag tnt-pipeline-etl:latest ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/tnt-pipeline-etl:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/tnt-pipeline-etl:latest
```

### Cost Optimization

**Production Costs (per 1000 files):**

- ECS File Scanner: $0.05 (single 2-minute task)
- ECS ETL Workers: $2.00 (1000 tasks × 2 minutes)
- DynamoDB: Negligible (on-demand)
- **Total: $2.05** (17% reduction from event-driven model)

## Monitoring & Observability

### 📊 **AWS CloudWatch**

- **ECS Logs**: `/ecs/file-scanner`, `/ecs/etl-worker`
- **Auto-scaling**: CPU-based scaling metrics
- **Cost Tracking**: AWS Cost Explorer integration

### 🔍 **Development Monitoring**

- **Health Checks**: Built-in health check endpoints
- **Structured Logging**: JSON-formatted logs with correlation IDs
- **Metrics**: Oban job metrics and processing statistics
- **Error Tracking**: Comprehensive error handling and reporting

### 🚨 **Production Monitoring**

```bash
# Monitor ECS tasks
aws ecs describe-tasks --cluster etl-cluster-prod --tasks $TASK_ARN

# Check auto-scaling
aws application-autoscaling describe-scaling-activities --service-namespace ecs

# View processing logs
aws logs tail /ecs/file-scanner --follow
aws logs tail /ecs/etl-worker --follow
```
