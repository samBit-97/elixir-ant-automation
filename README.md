# TntPipeline

## Overview

TntPipeline is an Elixir umbrella project designed to handle ETL (Extract, Transform, Load) processes efficiently. It provides a scalable, fault-tolerant pipeline for processing shipping data with S3 integration, background job processing via Oban, and comprehensive API enrichment capabilities.

## Project Structure

- **apps/etl_pipeline**: Main ETL application with data enrichment, validation, and API integration
- **apps/file_scanner**: S3 file discovery and job enqueueing service
- **apps/common**: Shared utilities, models, database, and AWS integrations

## Key Features

- 🚀 **Parallel Processing**: Uses Flow for concurrent data processing
- 📁 **S3 Integration**: Automated file discovery and streaming from AWS S3
- 🔄 **Background Jobs**: Oban-powered job queue for reliable processing
- 🧪 **High Test Coverage**: Comprehensive test suite with 30+ test cases
- 🐳 **Docker Support**: Containerized deployment with LocalStack for development
- ⚙️ **Environment-based Configuration**: Flexible config management for dev/test/prod

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

### Development Mode

```bash
# Start with environment variables
source .env && mix run --no-halt

# Or with specific apps
source .env && mix run --no-halt -e "FileScanner.Scanner.run()"
```

### File Scanner Service

```bash
# Scan all files in S3 bucket
mix file_scanner.run

# Scan with specific prefix
mix file_scanner.run "folder/subfolder"
```

### Docker Deployment

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

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  File Scanner   │───▶│     S3 Files     │───▶│  ETL Pipeline   │
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

## Monitoring & Observability

- **Health Checks**: Built-in health check endpoints
- **Structured Logging**: JSON-formatted logs with correlation IDs
- **Metrics**: Oban job metrics and processing statistics
- **Error Tracking**: Comprehensive error handling and reporting
