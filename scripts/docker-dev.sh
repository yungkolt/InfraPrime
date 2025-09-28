#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🐳 InfraPrime Docker Development${NC}"
echo "======================================"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker Desktop.${NC}"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose not found. Please install Docker Compose.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker environment ready${NC}"

# Function to show help
show_help() {
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start     Start all services"
    echo "  stop      Stop all services"
    echo "  restart   Restart all services"
    echo "  logs      Show logs for all services"
    echo "  status    Show status of all services"
    echo "  clean     Clean up containers and volumes"
    echo "  build     Build all images"
    echo "  test      Run tests"
    echo "  help      Show this help message"
    echo ""
}

# Function to start services
start_services() {
    echo -e "${YELLOW}Starting InfraPrime services...${NC}"
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
    
    echo -e "${YELLOW}Waiting for services to be ready...${NC}"
    sleep 10
    
    # Check if services are healthy
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Services started successfully!${NC}"
        echo ""
        echo "🌐 Application URLs:"
        echo "  Frontend: http://localhost:8080"
        echo "  Backend API: http://localhost:5000"
        echo "  Database Admin: http://localhost:5050"
        echo ""
        echo "📊 Health Check:"
        curl -s http://localhost:8080/health | python3 -m json.tool 2>/dev/null || echo "Health check endpoint not ready yet"
    else
        echo -e "${YELLOW}⚠️  Services are starting up. Please wait a moment and check http://localhost:8080${NC}"
    fi
}

# Function to stop services
stop_services() {
    echo -e "${YELLOW}Stopping InfraPrime services...${NC}"
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml down
    echo -e "${GREEN}✅ Services stopped${NC}"
}

# Function to show logs
show_logs() {
    echo -e "${YELLOW}Showing logs for all services...${NC}"
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml logs -f
}

# Function to show status
show_status() {
    echo -e "${YELLOW}Service Status:${NC}"
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps
    echo ""
    echo -e "${YELLOW}Docker Images:${NC}"
    docker images | grep infraprime
}

# Function to clean up
clean_up() {
    echo -e "${YELLOW}Cleaning up containers and volumes...${NC}"
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml down -v
    docker system prune -f
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Function to build images
build_images() {
    echo -e "${YELLOW}Building Docker images...${NC}"
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml build
    echo -e "${GREEN}✅ Images built successfully${NC}"
}

# Function to run tests
run_tests() {
    echo -e "${YELLOW}Running tests...${NC}"
    
    # Backend tests
    echo "Running backend tests..."
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec backend python -m pytest tests/ -v
    
    # Frontend tests
    echo "Running frontend tests..."
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec frontend npm test -- --watchAll=false
}

# Main script logic
case "${1:-start}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        stop_services
        start_services
        ;;
    logs)
        show_logs
        ;;
    status)
        show_status
        ;;
    clean)
        clean_up
        ;;
    build)
        build_images
        ;;
    test)
        run_tests
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
