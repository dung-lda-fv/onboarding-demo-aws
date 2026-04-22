#!/bin/bash
set -e

echo "🚀 Starting deployment..."

# 1. Start infrastructure
echo "📦 Starting LocalStack + services..."
docker compose up -d localstack
docker compose up -d --wait  # chờ healthcheck pass

# 2. Terraform init & apply
echo "🏗️  Running Terraform..."
docker compose exec terraform terraform init
docker compose exec terraform terraform plan
docker compose exec terraform terraform apply -auto-approve

# 3. Build & run app
echo "🐳 Building app..."
docker compose up -d --build app

echo "✅ Done! App running at http://localhost:3000"