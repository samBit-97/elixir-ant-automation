# TntPipeline

## Overview

TntPipeline is an Elixir-based project designed to handle ETL (Extract, Transform, Load) processes efficiently. It includes various components such as file streaming, data enrichment, and validation to ensure smooth data processing.

## Project Structure

- **apps/etl_pipeline**: Contains the main ETL logic, including file streaming, enrichment, and validation.
- **apps/file_scanner**: Handles file scanning operations.
- **apps/common**: Includes common utilities and models used across the project.

## Setup Instructions

1. **Clone the Repository**:

   ```bash
   git clone <repository-url>
   cd tnt_pipeline
   ```

2. **Install Dependencies**:

   ```bash
   mix deps.get
   ```

3. **Run Tests**:
   ```bash
   mix test
   ```

## Usage

- **Start the Application**:

  ```bash
  mix run --no-halt
  ```

- **Run in Docker**:
  Use the provided `docker-compose.yaml` to create postgres tables required for Oban
