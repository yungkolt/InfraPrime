#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}⚠️  This will clean up all Docker containers, images, and volumes!${NC}"
echo "This action cannot be undone."
echo ""
read -p "Are you sure you want to continue? Type 'clean' to confirm: " -r

if [[ ! $REPLY == "clean" ]]; then
    echo -e "${GREEN}Cleanup cancelled.${NC}"
    exit 0
fi

echo -e "${RED}🗑️  Cleaning up Docker resources...${NC}"

# Stop and remove containers
echo -e "${YELLOW}Stopping and removing containers...${NC}"
docker-compose -f docker-compose.yml -f docker-compose.dev.yml down -v

# Remove InfraPrime images
echo -e "${YELLOW}Removing InfraPrime images...${NC}"
docker images | grep infraprime | awk '{print $3}' | xargs -r docker rmi -f

# Remove unused images
echo -e "${YELLOW}Removing unused images...${NC}"
docker image prune -f

# Remove unused volumes
echo -e "${YELLOW}Removing unused volumes...${NC}"
docker volume prune -f

# Remove unused networks
echo -e "${YELLOW}Removing unused networks...${NC}"
docker network prune -f

# Clean up build cache
echo -e "${YELLOW}Cleaning up build cache...${NC}"
docker builder prune -f

echo -e "${GREEN}✅ Cleanup completed successfully!${NC}"
echo ""
echo "To start fresh:"
echo "  ./scripts/setup.sh"
