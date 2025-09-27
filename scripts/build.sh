#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="infraprime"
IMAGE_TAG="${1:-latest}"

echo -e "${GREEN}🔨 Building Docker Images${NC}"
echo "======================================"
echo "Image tag: ${IMAGE_TAG}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker Desktop.${NC}"
    exit 1
fi

# Build backend image
echo -e "${YELLOW}Building backend image...${NC}"
cd application/backend
docker build -t "${PROJECT_NAME}-backend:${IMAGE_TAG}" .
docker build -t "${PROJECT_NAME}-backend:latest" .

echo -e "${GREEN}✅ Backend image built successfully${NC}"

# Build frontend image
echo -e "${YELLOW}Building frontend image...${NC}"
cd ../frontend
docker build -t "${PROJECT_NAME}-frontend:${IMAGE_TAG}" .
docker build -t "${PROJECT_NAME}-frontend:latest" .

echo -e "${GREEN}✅ Frontend image built successfully${NC}"

# Show built images
echo ""
echo -e "${YELLOW}Built Images:${NC}"
docker images | grep "${PROJECT_NAME}"

echo ""
echo -e "${GREEN}✅ All images built successfully!${NC}"
echo ""
echo "To run the application:"
echo "  ./scripts/docker-dev.sh start"
echo ""
echo "To run with specific tag:"
echo "  docker-compose -f docker-compose.yml up -d"
