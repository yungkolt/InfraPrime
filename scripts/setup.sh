#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="infraprime"

echo -e "${GREEN}🚀 InfraPrime Docker Setup${NC}"
echo "======================================"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found. Please install Docker Desktop.${NC}"
    echo "Download from: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose not found. Please install Docker Compose.${NC}"
    echo "Docker Compose is usually included with Docker Desktop"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker Desktop.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Check Node.js for frontend development
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}⚠️  Node.js not found. Frontend development features may be limited.${NC}"
    echo "Install Node.js from: https://nodejs.org/"
else
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✅ Node.js found: ${NODE_VERSION}${NC}"
fi

# Check Python for backend development
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}⚠️  Python3 not found. Backend development features may be limited.${NC}"
    echo "Install Python from: https://python.org/"
else
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✅ Python found: ${PYTHON_VERSION}${NC}"
fi

# Create necessary directories
echo -e "${YELLOW}Creating necessary directories...${NC}"
mkdir -p logs
mkdir -p application/backend/logs

# Set up environment files
echo -e "${YELLOW}Setting up environment configuration...${NC}"

# Backend environment
if [ ! -f application/backend/.env ]; then
    cat > application/backend/.env << EOF
# Development Environment
FLASK_ENV=development
FLASK_DEBUG=1
DATABASE_URL=postgresql://admin:dev_password_123@database:5432/infraprime
REDIS_URL=redis://redis:6379/0
SECRET_KEY=dev-secret-key-change-in-production
API_VERSION=1.0.0
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
LOG_LEVEL=DEBUG
EOF
    echo -e "${GREEN}✅ Backend environment file created${NC}"
fi

# Frontend environment
if [ ! -f application/frontend/.env ]; then
    cat > application/frontend/.env << EOF
# Development Environment
NODE_ENV=development
REACT_APP_API_URL=http://localhost:5000
REACT_APP_ENV=development
CHOKIDAR_USEPOLLING=true
EOF
    echo -e "${GREEN}✅ Frontend environment file created${NC}"
fi

# Build Docker images
echo -e "${YELLOW}Building Docker images...${NC}"
./scripts/build.sh

echo -e "${GREEN}✅ Setup completed successfully!${NC}"
echo ""
echo "🎉 InfraPrime is ready to use!"
echo ""
echo "Quick Start Commands:"
echo "  ./scripts/docker-dev.sh start    # Start all services"
echo "  ./scripts/docker-dev.sh stop     # Stop all services"
echo "  ./scripts/docker-dev.sh logs     # View logs"
echo "  ./scripts/docker-dev.sh status   # Check status"
echo "  ./scripts/docker-dev.sh test     # Run tests"
echo ""
echo "🌐 Application URLs (after starting):"
echo "  Frontend: http://localhost:8080"
echo "  Backend API: http://localhost:5000"
echo "  Database Admin: http://localhost:5050"
echo "  Monitoring: http://localhost:3001"
echo ""
echo "📚 Documentation:"
echo "  See docs/ directory for detailed guides"
