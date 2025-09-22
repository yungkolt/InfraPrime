#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ENVIRONMENT="${1:-dev}"

echo -e "${YELLOW}⚠️  This will destroy all resources for ${ENVIRONMENT} environment!${NC}"
echo "This action cannot be undone."
echo ""
read -p "Are you sure you want to continue? Type 'destroy' to confirm: " -r

if [[ ! $REPLY == "destroy" ]]; then
    echo -e "${GREEN}Cleanup cancelled.${NC}"
    exit 0
fi

echo -e "${RED}🗑️  Destroying infrastructure...${NC}"

cd terraform

# Destroy infrastructure
terraform destroy \
    -var="environment=${ENVIRONMENT}" \
    -auto-approve

echo -e "${GREEN}✅ Infrastructure destroyed successfully!${NC}"

# scripts/health-check.sh
#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🏥 Health Check${NC}"
echo "======================================"

cd terraform

# Get URLs from Terraform outputs
ALB_URL=$(terraform output -raw alb_url 2>/dev/null || echo "")
CLOUDFRONT_URL=$(terraform output -raw cloudfront_url 2>/dev/null || echo "")

if [ -z "$ALB_URL" ]; then
    echo -e "${RED}❌ Could not get deployment URLs. Infrastructure may not be deployed.${NC}"
    exit 1
fi

echo "Backend URL: ${ALB_URL}"
echo "Frontend URL: ${CLOUDFRONT_URL}"
echo ""

# Check backend health
echo -e "${YELLOW}Checking backend health...${NC}"
if curl -f -s "${ALB_URL}/health" > /dev/null; then
    echo -e "${GREEN}✅ Backend is healthy${NC}"
    
    # Get health details
    echo "Health details:"
    curl -s "${ALB_URL}/health" | python3 -m json.tool
else
    echo -e "${RED}❌ Backend health check failed${NC}"
    exit 1
fi

echo ""

# Check frontend
if [ ! -z "$CLOUDFRONT_URL" ]; then
    echo -e "${YELLOW}Checking frontend...${NC}"
    if curl -f -s "${CLOUDFRONT_URL}" > /dev/null; then
        echo -e "${GREEN}✅ Frontend is accessible${NC}"
    else
        echo -e "${RED}❌ Frontend is not accessible${NC}"
    fi
fi

echo ""

# Test API endpoints
echo -e "${YELLOW}Testing API endpoints...${NC}"

# Test data endpoint
if curl -f -s "${ALB_URL}/api/data" > /dev/null; then
    echo -e "${GREEN}✅ /api/data endpoint working${NC}"
else
    echo -e "${RED}❌ /api/data endpoint failed${NC}"
fi

# Test stats endpoint
if curl -f -s "${ALB_URL}/api/stats" > /dev/null; then
    echo -e "${GREEN}✅ /api/stats endpoint working${NC}"
else
    echo -e "${RED}❌ /api/stats endpoint failed${NC}"
fi

# Test database endpoint
if curl -f -s "${ALB_URL}/api/test-db" > /dev/null; then
    echo -e "${GREEN}✅ Database connectivity working${NC}"
else
    echo -e "${RED}❌ Database connectivity failed${NC}"
fi

echo ""
echo -e "${GREEN}✅ Health check completed!${NC}"
