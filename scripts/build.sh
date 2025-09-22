#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="three-tier-app"
AWS_REGION="${AWS_REGION:-us-east-1}"
IMAGE_TAG="${1:-latest}"

echo -e "${GREEN}🔨 Building and Pushing Docker Image${NC}"
echo "======================================"
echo "Image tag: ${IMAGE_TAG}"
echo ""

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_REPO="${PROJECT_NAME}-backend"
FULL_IMAGE_URI="${ECR_URI}/${ECR_REPO}:${IMAGE_TAG}"

echo "ECR Repository: ${ECR_URI}/${ECR_REPO}"
echo ""

# Login to ECR
echo -e "${YELLOW}Logging in to Amazon ECR...${NC}"
aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_URI}"

# Build Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
cd application/backend
docker build -t "${ECR_REPO}:${IMAGE_TAG}" .

# Tag image for ECR
docker tag "${ECR_REPO}:${IMAGE_TAG}" "${FULL_IMAGE_URI}"
docker tag "${ECR_REPO}:${IMAGE_TAG}" "${ECR_URI}/${ECR_REPO}:latest"

# Push image to ECR
echo -e "${YELLOW}Pushing image to ECR...${NC}"
docker push "${FULL_IMAGE_URI}"
docker push "${ECR_URI}/${ECR_REPO}:latest"

echo -e "${GREEN}✅ Image pushed successfully!${NC}"
echo "Image URI: ${FULL_IMAGE_URI}"

# Update ECS service if it exists
echo -e "${YELLOW}Updating ECS service...${NC}"
cd ../../terraform

if terraform show | grep -q "aws_ecs_service.backend"; then
    # Update terraform.tfvars with new image tag
    sed -i.bak "s/image_tag = .*/image_tag = \"${IMAGE_TAG}\"/" terraform.tfvars
    
    # Apply terraform to update the service
    terraform plan -var="image_tag=${IMAGE_TAG}" -out=tfplan
    terraform apply tfplan
    
    echo -e "${GREEN}✅ ECS service updated with new image${NC}"
else
    echo -e "${YELLOW}⚠️  ECS service not found. Deploy infrastructure first.${NC}"
fi

# scripts/deploy-frontend.sh
#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🌐 Deploying Frontend to S3${NC}"
echo "======================================"

# Get S3 bucket name from Terraform
cd terraform
S3_BUCKET=$(terraform output -raw s3_bucket_name)
ALB_URL=$(terraform output -raw alb_url)
CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")

if [ -z "$S3_BUCKET" ]; then
    echo -e "${RED}❌ Could not get S3 bucket name. Deploy infrastructure first.${NC}"
    exit 1
fi

cd ../application/frontend

echo "S3 Bucket: ${S3_BUCKET}"
echo "Backend URL: ${ALB_URL}"
echo ""

# Update frontend configuration
echo -e "${YELLOW}Updating frontend configuration...${NC}"
cp src/app.js src/app.js.bak
sed "s|http://localhost:5000|${ALB_URL}|g" src/app.js.bak > src/app.js

# Deploy to S3
echo -e "${YELLOW}Uploading files to S3...${NC}"
aws s3 sync src/ "s3://${S3_BUCKET}/" --delete

# Invalidate CloudFront cache if distribution exists
if [ ! -z "$CLOUDFRONT_ID" ]; then
    echo -e "${YELLOW}Invalidating CloudFront cache...${NC}"
    aws cloudfront create-invalidation \
        --distribution-id "$CLOUDFRONT_ID" \
        --paths "/*"
fi

# Restore original file
mv src/app.js.bak src/app.js

echo -e "${GREEN}✅ Frontend deployed successfully!${NC}"
