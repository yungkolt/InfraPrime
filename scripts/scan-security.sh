#!/bin/bash

# InfraPrime Security Scanning Script
# This script uses Trivy to scan Docker images for vulnerabilities

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔒 InfraPrime Security Scanner${NC}"
echo "=================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Check if images exist
echo -e "${YELLOW}📋 Checking for available images...${NC}"

if ! docker image inspect infraprime-backend:latest > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  infraprime-backend:latest not found. Building images first...${NC}"
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml build backend
fi

# Start Trivy service
echo -e "${YELLOW}🚀 Starting Trivy security scanner...${NC}"
docker-compose -f docker-compose.yml -f docker-compose.dev.yml --profile security up -d trivy

# Wait for Trivy to be ready
echo -e "${YELLOW}⏳ Waiting for Trivy to initialize...${NC}"
sleep 5

# Function to run Trivy scan
run_scan() {
    local image=$1
    local severity=${2:-"HIGH,CRITICAL"}
    local format=${3:-"table"}
    
    echo -e "${BLUE}🔍 Scanning $image (Severity: $severity)${NC}"
    echo "----------------------------------------"
    
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec -T trivy trivy image \
        --format "$format" \
        --severity "$severity" \
        --exit-code 1 \
        "$image"
}

# Scan backend image
echo -e "${GREEN}🎯 Starting security scan...${NC}"
echo ""

# Scan with different severity levels
echo -e "${YELLOW}1. Critical and High severity vulnerabilities:${NC}"
if run_scan "infraprime-backend:latest" "HIGH,CRITICAL" "table"; then
    echo -e "${GREEN}✅ No HIGH or CRITICAL vulnerabilities found!${NC}"
else
    echo -e "${RED}❌ HIGH or CRITICAL vulnerabilities detected!${NC}"
fi

echo ""
echo -e "${YELLOW}2. All vulnerabilities (including Medium and Low):${NC}"
run_scan "infraprime-backend:latest" "LOW,MEDIUM,HIGH,CRITICAL" "table" || true

echo ""
echo -e "${YELLOW}3. JSON report (for CI/CD integration):${NC}"
run_scan "infraprime-backend:latest" "HIGH,CRITICAL" "json" || true

echo ""
echo -e "${GREEN}✅ Security scan completed!${NC}"
echo ""
echo -e "${BLUE}💡 Tips:${NC}"
echo "  - Run 'docker-compose exec trivy trivy image infraprime-backend:latest' for manual scans"
echo "  - Use '--severity HIGH,CRITICAL' to focus on critical issues"
echo "  - Use '--format json' for programmatic processing"
echo ""
echo -e "${YELLOW}🛑 To stop Trivy: docker-compose --profile security down${NC}"
