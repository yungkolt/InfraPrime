#!/bin/bash

# InfraPrime Security Scanner
# Automated Trivy vulnerability scanning for Docker images

set -e

echo "🔒 InfraPrime Security Scanner"
echo "=============================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Start Trivy service
echo "🚀 Starting Trivy security scanner..."
docker-compose -f docker-compose.yml -f docker-compose.dev.yml --profile security up -d

# Wait for Trivy to be ready
echo "⏳ Waiting for Trivy to initialize..."
sleep 3

# Run security scan
echo "🔍 Scanning infraprime-backend:latest for HIGH and CRITICAL vulnerabilities..."
echo ""

docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec trivy trivy image \
    --format table \
    --severity HIGH,CRITICAL \
    infraprime-backend:latest

echo ""
echo "✅ Security scan completed!"
echo ""
echo "💡 Manual commands:"
echo "  docker-compose exec trivy trivy image infraprime-backend:latest"
echo "  docker-compose --profile security down"
