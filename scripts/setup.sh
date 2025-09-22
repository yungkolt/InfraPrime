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
ENVIRONMENT="${ENVIRONMENT:-dev}"

echo -e "${GREEN}🚀 Three-Tier Application Setup${NC}"
echo "======================================"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not found. Please install AWS CLI.${NC}"
    exit 1
fi

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform not found. Please install Terraform.${NC}"
    exit 1
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found. Please install Docker.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Check AWS credentials
echo -e "${YELLOW}Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure'.${NC}"
    exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✅ AWS credentials configured for account: ${AWS_ACCOUNT_ID}${NC}"

# Create S3 bucket for Terraform state
echo -e "${YELLOW}Setting up Terraform backend...${NC}"
STATE_BUCKET="${PROJECT_NAME}-terraform-state-${AWS_ACCOUNT_ID}-${AWS_REGION}"
LOCK_TABLE="${PROJECT_NAME}-terraform-lock"

# Create S3 bucket if it doesn't exist
if ! aws s3 ls "s3://${STATE_BUCKET}" 2>&1 | grep -q 'NoSuchBucket'; then
    echo "S3 bucket ${STATE_BUCKET} already exists"
else
    echo "Creating S3 bucket: ${STATE_BUCKET}"
    aws s3 mb "s3://${STATE_BUCKET}" --region "${AWS_REGION}"
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "${STATE_BUCKET}" \
        --versioning-configuration Status=Enabled
    
    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket "${STATE_BUCKET}" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'
fi

# Create DynamoDB table for state locking
if ! aws dynamodb describe-table --table-name "${LOCK_TABLE}" &> /dev/null; then
    echo "Creating DynamoDB table: ${LOCK_TABLE}"
    aws dynamodb create-table \
        --table-name "${LOCK_TABLE}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
        --region "${AWS_REGION}"
    
    echo "Waiting for DynamoDB table to be created..."
    aws dynamodb wait table-exists --table-name "${LOCK_TABLE}" --region "${AWS_REGION}"
else
    echo "DynamoDB table ${LOCK_TABLE} already exists"
fi

# Create ECR repository
echo -e "${YELLOW}Setting up ECR repository...${NC}"
ECR_REPO="${PROJECT_NAME}-backend"
if ! aws ecr describe-repositories --repository-names "${ECR_REPO}" &> /dev/null; then
    echo "Creating ECR repository: ${ECR_REPO}"
    aws ecr create-repository --repository-name "${ECR_REPO}" --region "${AWS_REGION}"
else
    echo "ECR repository ${ECR_REPO} already exists"
fi

# Update backend configuration in Terraform
echo -e "${YELLOW}Updating Terraform backend configuration...${NC}"
cat > terraform/backend.tf << EOF
terraform {
  backend "s3" {
    bucket         = "${STATE_BUCKET}"
    key            = "three-tier-app/terraform.tfstate"
    region         = "${AWS_REGION}"
    encrypt        = true
    dynamodb_table = "${LOCK_TABLE}"
  }
}
EOF

# Create terraform.tfvars if it doesn't exist
if [ ! -f terraform/terraform.tfvars ]; then
    echo -e "${YELLOW}Creating terraform.tfvars...${NC}"
    cat > terraform/terraform.tfvars << EOF
# Basic Configuration
project_name = "${PROJECT_NAME}"
environment  = "${ENVIRONMENT}"
aws_region   = "${AWS_REGION}"
owner        = "$(whoami)"
cost_center  = "Personal"

# Network Configuration
vpc_cidr           = "10.0.0.0/16"
enable_nat_gateway = true

# Database Configuration
database_name     = "threetierapp"
database_username = "dbadmin"
db_instance_class = "db.t3.micro"
allocated_storage = 20

# ECS Configuration
desired_count = 1
task_cpu      = 512
task_memory   = 1024
image_tag     = "latest"

# Monitoring
notification_email = "your-email@example.com"
EOF
    echo -e "${YELLOW}⚠️  Please update terraform.tfvars with your email address${NC}"
fi

echo -e "${GREEN}✅ Setup completed successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Update terraform/terraform.tfvars with your email address"
echo "2. Run './scripts/deploy.sh' to deploy the infrastructure"
echo "3. Run './scripts/build.sh' to build and push the application"
