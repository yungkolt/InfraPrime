# InfraPrime Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [AWS Setup](#aws-setup)
3. [Local Development](#local-development)
4. [Production Deployment](#production-deployment)
5. [CI/CD Pipeline](#cicd-pipeline)
6. [Monitoring Setup](#monitoring-setup)
7. [Backup and Recovery](#backup-and-recovery)

## Prerequisites

### Required Tools
- **AWS CLI** (v2.0+): `aws --version`
- **Terraform** (v1.5+): `terraform --version`
- **Docker** (v20.0+): `docker --version`
- **Docker Compose** (v2.0+): `docker-compose --version`
- **Git**: `git --version`
- **Node.js** (v18+): `node --version`
- **Python** (v3.9+): `python --version`

### AWS Requirements
- AWS Account with billing enabled
- IAM user with programmatic access
- Required IAM permissions (see `docs/iam-permissions.json`)
- S3 bucket for Terraform state storage

## AWS Setup

### 1. Configure AWS CLI
```bash
aws configure
# AWS Access Key ID: [your-access-key]
# AWS Secret Access Key: [your-secret-key]
# Default region name: us-east-1
# Default output format: json
```

### 2. Verify AWS Access
```bash
aws sts get-caller-identity
aws ec2 describe-regions --region us-east-1
```

### 3. Create Terraform State Bucket
```bash
aws s3 mb s3://your-terraform-state-bucket-name
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket-name \
  --versioning-configuration Status=Enabled
```

## Local Development

### Option 1: Docker Compose (Recommended)
```bash
# Clone the repository
git clone <your-repo-url>
cd InfraPrime

# Start development environment
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Access the application
open http://localhost:8080
```

### Option 2: Native Development
```bash
# Backend setup
cd application/backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
export DATABASE_URL="postgresql://admin:dev_password_123@localhost:5432/infraprime"
python app.py

# Frontend setup (new terminal)
cd application/frontend
npm install
npm run dev
```

## Production Deployment

### Step 1: Configure Terraform Variables
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
# Required Variables
aws_region = "us-east-1"
environment = "prod"
project_name = "infraprime"

# Networking
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# Compute
instance_type = "t3.medium"
min_capacity = 2
max_capacity = 10
desired_capacity = 3

# Database
db_instance_class = "db.t3.micro"
database_name = "infraprime"
database_username = "admin"
database_password = "secure-password-change-me"

# Domain (optional)
domain_name = "infraprime.com"
create_route53_zone = true

# Tags
tags = {
  Project = "InfraPrime"
  Owner = "YourName"
  Environment = "production"
}
```

### Step 2: Initialize and Deploy Infrastructure
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="terraform.tfvars"

# Apply infrastructure
terraform apply -var-file="terraform.tfvars"

# Note the outputs
terraform output
```

### Step 3: Build and Deploy Application
```bash
# Build and push Docker image
./scripts/build.sh

# Deploy application
./scripts/deploy.sh
```

### Step 4: Verify Deployment
```bash
# Get ALB URL from Terraform output
ALB_URL=$(terraform output -raw alb_dns_name)

# Test health endpoint
curl https://$ALB_URL/health

# Test API endpoint
curl https://$ALB_URL/api/data
```

## CI/CD Pipeline

### GitHub Actions Setup

1. **Add Repository Secrets:**
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `DATABASE_PASSWORD`
   - `SECRET_KEY`

2. **Enable Actions:**
   - Push to `main` branch triggers production deployment
   - Push to `develop` branch triggers staging deployment
   - Pull requests trigger testing and validation

3. **Pipeline Stages:**
   ```yaml
   stages:
     - Test: Unit tests, integration tests, security scans
     - Build: Docker image build and push to ECR
     - Deploy: Terraform plan and apply
     - Verify: Health checks and smoke tests
   ```

### Manual Deployment Commands
```bash
# Deploy to staging
./scripts/deploy.sh staging

# Deploy to production
./scripts/deploy.sh production

# Rollback deployment
./scripts/rollback.sh <previous-version>
```

## Monitoring Setup

### CloudWatch Dashboards
Terraform automatically creates:
- **Infrastructure Dashboard**: EC2, RDS, ALB metrics
- **Application Dashboard**: Custom application metrics
- **Security Dashboard**: Failed logins, error rates

### Alerts Configuration
Default alerts configured for:
- High CPU usage (>80% for 5 minutes)
- High memory usage (>85% for 5 minutes)
- Database connection errors
- Application error rates (>5% for 5 minutes)
- ALB 5xx errors

### Log Aggregation
- Application logs → CloudWatch Logs
- Access logs → S3 bucket
- Error logs → CloudWatch Logs with alerts

### Custom Metrics
```python
# Example: Publishing custom metrics from application
import boto3

cloudwatch = boto3.client('cloudwatch')
cloudwatch.put_metric_data(
    Namespace='InfraPrime/Application',
    MetricData=[
        {
            'MetricName': 'BusinessMetric',
            'Value': 123.45,
            'Unit': 'Count'
        }
    ]
)
```

## Backup and Recovery

### Database Backups
- **Automated**: Daily RDS snapshots (7-day retention)
- **Manual**: On-demand snapshots before major deployments
- **Cross-region**: Weekly snapshots replicated to secondary region

### Application Data Backups
- **User uploads**: S3 with versioning enabled
- **Configuration**: Terraform state in S3 with versioning
- **Secrets**: AWS Secrets Manager with automatic rotation

### Disaster Recovery Procedures

#### RDS Restoration
```bash
# List available snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier infraprime-db-prod

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier infraprime-db-restored \
  --db-snapshot-identifier <snapshot-id>
```

#### Full Environment Recreation
```bash
# From Terraform state
terraform apply -var-file="terraform.tfvars"

# Restore database from backup
./scripts/restore-database.sh <snapshot-id>

# Redeploy application
./scripts/deploy.sh production
```

### Recovery Time Objectives (RTO) and Recovery Point Objectives (RPO)
- **RTO**: 2 hours (complete environment recreation)
- **RPO**: 1 hour (maximum data loss from last backup)

## Environment-Specific Configurations

### Development
- Single AZ deployment
- Smaller instance sizes
- Debug logging enabled
- No SSL termination at ALB

### Staging
- Multi-AZ deployment
- Production-like sizing
- SSL with self-signed certificates
- Limited retention periods

### Production
- Multi-AZ with auto-scaling
- Production instance sizes
- SSL with valid certificates
- Extended backup retention
- Enhanced monitoring and alerting

## Cost Optimization

### Current Cost Estimates (Monthly)
- **Development**: ~$50-75
- **Staging**: ~$150-200
- **Production**: ~$300-500

### Cost Optimization Strategies
1. **Auto-scaling**: Reduce instances during low usage
2. **Spot instances**: Use for non-critical workloads
3. **Reserved instances**: For predictable workloads
4. **S3 lifecycle policies**: Move old data to cheaper storage tiers
5. **CloudWatch log retention**: Adjust retention periods

### Cost Monitoring
```bash
# Check current costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

## Troubleshooting Common Issues

### Deployment Failures
1. **Terraform state lock**: `terraform force-unlock <lock-id>`
2. **ECR permissions**: Check IAM roles and policies
3. **VPC limits**: Verify AWS service quotas

### Application Issues
1. **ECS task failures**: Check CloudWatch logs
2. **Database connections**: Verify security groups
3. **Load balancer health checks**: Check target group settings

### Networking Issues
1. **DNS resolution**: Verify Route53 configuration
2. **SSL certificates**: Check ACM certificate validation
3. **NAT Gateway**: Verify outbound internet connectivity

## Security Checklist

- [ ] IAM roles follow least-privilege principle
- [ ] Security groups restrict access to necessary ports only
- [ ] Database encryption at rest enabled
- [ ] SSL/TLS encryption in transit
- [ ] WAF rules configured for ALB
- [ ] VPC Flow Logs enabled
- [ ] CloudTrail logging enabled
- [ ] Secrets stored in AWS Secrets Manager
- [ ] Regular security scans with tools like `tfsec`

## Next Steps After Deployment

1. **Set up monitoring alerts**: Configure PagerDuty or similar
2. **Performance testing**: Run load tests against the environment
3. **Security assessment**: Conduct penetration testing
4. **Documentation updates**: Keep runbooks current
5. **Team training**: Ensure team members understand the deployment process

## Support and Maintenance

### Regular Maintenance Tasks
- **Weekly**: Review CloudWatch metrics and alerts
- **Monthly**: Update dependencies and security patches
- **Quarterly**: Review and optimize costs
- **Annually**: Architecture review and capacity planning

### Emergency Contacts
- **On-call Engineer**: [Your contact information]
- **AWS Support**: [Your support plan details]
- **Escalation**: [Manager/team lead contact]

---

For additional help, see:
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Security Documentation](SECURITY.md)
- [Architecture Decisions](docs/architecture-decisions/)
