#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="${1:-dev}"
PROJECT_NAME="three-tier-app"

echo -e "${GREEN}🚀 Deploying Three-Tier Application${NC}"
echo "======================================"
echo "Environment: ${ENVIRONMENT}"
echo ""

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo -e "${RED}❌ Invalid environment. Use: dev, staging, or prod${NC}"
    exit 1
fi

# Change to terraform directory
cd terraform

# Initialize Terraform
echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init

# Validate Terraform configuration
echo -e "${YELLOW}Validating Terraform configuration...${NC}"
terraform validate

# Plan Terraform deployment
echo -e "${YELLOW}Planning Terraform deployment...${NC}"
terraform plan \
    -var="environment=${ENVIRONMENT}" \
    -out=tfplan

# Ask for confirmation
echo ""
echo -e "${BLUE}Ready to apply Terraform plan for ${ENVIRONMENT} environment.${NC}"
read -p "Do you want to continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled.${NC}"
    exit 0
fi

# Apply Terraform plan
echo -e "${YELLOW}Applying Terraform plan...${NC}"
terraform apply tfplan

# Get outputs
echo -e "${GREEN}Getting deployment information...${NC}"
ALB_URL=$(terraform output -raw alb_url)
CLOUDFRONT_URL=$(terraform output -raw cloudfront_url)
S3_BUCKET=$(terraform output -raw s3_bucket_name)

echo ""
echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo ""
echo "Deployment URLs:"
echo "Backend API: ${ALB_URL}"
echo "Frontend: ${CLOUDFRONT_URL}"
echo "S3 Bucket: ${S3_BUCKET}"
echo ""
echo "Next steps:"
echo "1. Build and push the Docker image: ./scripts/build.sh"
echo "2. Deploy the frontend: ./scripts/deploy-frontend.sh"
