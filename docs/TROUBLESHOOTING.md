# InfraPrime Troubleshooting Guide

## Table of Contents
1. [Common Issues](#common-issues)
2. [Infrastructure Problems](#infrastructure-problems)
3. [Application Issues](#application-issues)
4. [Database Problems](#database-problems)
5. [Networking Issues](#networking-issues)
6. [Security Issues](#security-issues)
7. [Performance Problems](#performance-problems)
8. [Debugging Tools](#debugging-tools)

## Common Issues

### 1. Terraform State Lock Error
**Problem**: `Error: Error locking state: Error acquiring the state lock`

**Solutions**:
```bash
# Option 1: Force unlock (use with caution)
terraform force-unlock <lock-id>

# Option 2: Check who has the lock
aws dynamodb get-item \
  --table-name terraform-state-lock \
  --key '{"LockID":{"S":"infraprime/terraform.tfstate"}}'

# Option 3: Manual cleanup if lock is stale
aws dynamodb delete-item \
  --table-name terraform-state-lock \
  --key '{"LockID":{"S":"infraprime/terraform.tfstate"}}'
```

### 2. ECR Image Pull Errors
**Problem**: `Failed to pull image: pull access denied`

**Solutions**:
```bash
# Check ECR permissions
aws ecr get-authorization-token

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Verify image exists
aws ecr describe-images --repository-name infraprime-backend

# Check ECS task execution role permissions
aws iam get-role --role-name ecsTaskExecutionRole
```

### 3. Application Won't Start
**Problem**: ECS tasks keep stopping or failing health checks

**Debugging Steps**:
```bash
# Check ECS service events
aws ecs describe-services \
  --cluster infraprime-cluster \
  --services infraprime-backend-service

# Check task definition
aws ecs describe-task-definition \
  --task-definition infraprime-backend

# View container logs
aws logs get-log-events \
  --log-group-name /ecs/infraprime-backend \
  --log-stream-name <log-stream-name>

# Check task status
aws ecs describe-tasks \
  --cluster infraprime-cluster \
  --tasks <task-arn>
```

## Infrastructure Problems

### Terraform Apply Failures

#### Resource Already Exists
**Error**: `ResourceAlreadyExistsException`
```bash
# Import existing resource
terraform import aws_security_group.example sg-12345678

# Or modify resource name in configuration
```

#### Insufficient Permissions
**Error**: `AccessDenied` or `UnauthorizedOperation`
```bash
# Check current IAM permissions
aws sts get-caller-identity
aws iam get-user
aws iam list-attached-user-policies --user-name <username>

# Test specific permissions
aws ec2 describe-vpcs --dry-run
```

#### Resource Limits Exceeded
**Error**: `LimitExceededException`
```bash
# Check service quotas
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-34B43A08  # Running On-Demand EC2 instances

# Request quota increase
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code L-34B43A08 \
  --desired-value 50
```

### VPC and Networking Issues

#### No Available IP Addresses
**Problem**: `InsufficientFreeAddressesInSubnet`
```bash
# Check subnet utilization
aws ec2 describe-subnets --subnet-ids subnet-12345

# Calculate available IPs
# Formula: (2^(32-subnet_mask)) - 5 (AWS reserves 5 IPs)

# Solution: Create larger subnet or additional subnets
```

#### NAT Gateway Issues
**Problem**: Instances can't reach internet
```bash
# Check NAT Gateway status
aws ec2 describe-nat-gateways

# Verify route tables
aws ec2 describe-route-tables

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-12345
```

## Application Issues

### ECS Service Problems

#### Tasks Keep Stopping
**Debugging**:
```bash
# Check stopped tasks
aws ecs list-tasks --cluster infraprime-cluster --desired-status STOPPED

# Get stop reason
aws ecs describe-tasks --cluster infraprime-cluster --tasks <task-arn>

# Common reasons and solutions:
# - Memory limit exceeded: Increase task memory
# - Health check failures: Fix application /health endpoint
# - Container exits: Check application logs for errors
```

#### Service Not Scaling
**Problem**: Auto Scaling not working
```bash
# Check Auto Scaling configuration
aws application-autoscaling describe-scalable-targets \
  --service-namespace ecs

# Check CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 300 \
  --statistics Average
```

### Load Balancer Issues

#### Health Check Failures
**Problem**: Targets showing as unhealthy
```bash
# Check target group health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Common fixes:
# 1. Verify health check path exists (/health)
# 2. Check security group allows health check port
# 3. Ensure application starts within timeout period
# 4. Verify health check returns 200 status code
```

#### SSL Certificate Issues
**Problem**: SSL/TLS handshake failures
```bash
# Check certificate status
aws acm describe-certificate --certificate-arn <cert-arn>

# Verify domain validation
aws route53 list-resource-record-sets --hosted-zone-id <zone-id>

# Test SSL connection
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

## Database Problems

### RDS Connection Issues

#### Can't Connect to Database
**Problem**: Connection timeouts or refused connections
```bash
# Check RDS instance status
aws rds describe-db-instances --db-instance-identifier infraprime-db

# Verify security group rules
aws ec2 describe-security-groups --group-ids sg-database

# Test connection from ECS task
aws ecs run-task \
  --cluster infraprime-cluster \
  --task-definition debug-task \
  --overrides '{
    "containerOverrides": [{
      "name": "debug",
      "command": ["psql", "-h", "database-endpoint", "-U", "admin", "-d", "infraprime"]
    }]
  }'
```

#### High Database CPU
**Problem**: Database performance issues
```bash
# Check performance insights
aws rds describe-db-instances \
  --db-instance-identifier infraprime-db \
  --query 'DBInstances[0].PerformanceInsightsEnabled'

# Check slow queries
# Connect to database and run:
# SELECT query, calls, total_time, mean_time
# FROM pg_stat_statements
# ORDER BY total_time DESC
# LIMIT 10;
```

#### Storage Issues
**Problem**: Running out of disk space
```bash
# Check storage metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name FreeStorageSpace \
  --dimensions Name=DBInstanceIdentifier,Value=infraprime-db \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average

# Enable storage autoscaling if not already enabled
aws rds modify-db-instance \
  --db-instance-identifier infraprime-db \
  --max-allocated-storage 1000
```

## Networking Issues

### DNS Resolution Problems

#### Domain Not Resolving
**Problem**: DNS queries failing
```bash
# Check Route53 hosted zone
aws route53 list-hosted-zones

# Verify DNS records
aws route53 list-resource-record-sets --hosted-zone-id <zone-id>

# Test DNS resolution
dig your-domain.com
nslookup your-domain.com

# Check if using custom DNS servers
dig @8.8.8.8 your-domain.com
```

### VPC Connectivity Issues

#### Cross-AZ Communication Problems
**Problem**: Resources in different AZs can't communicate
```bash
# Check VPC configuration
aws ec2 describe-vpcs --vpc-ids vpc-12345

# Verify subnet routing
aws ec2 describe-route-tables

# Check NACLs (Network ACLs)
aws ec2 describe-network-acls --filters "Name=vpc-id,Values=vpc-12345"
```

#### Internet Gateway Issues
**Problem**: No internet connectivity
```bash
# Check if IGW is attached
aws ec2 describe-internet-gateways

# Verify route table has route to IGW
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-12345"

# Should see route: 0.0.0.0/0 -> igw-12345
```

## Security Issues

### IAM Permission Problems

#### Access Denied Errors
**Problem**: AWS API calls failing with 403
```bash
# Check current permissions
aws sts get-caller-identity

# Simulate specific action
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:user/test-user \
  --action-names ec2:DescribeInstances \
  --resource-arns "*"

# Debug with CloudTrail
aws logs filter-log-events \
  --log-group-name CloudTrail/APIGateway \
  --filter-pattern '{ $.errorCode = "AccessDenied" }'
```

### Security Group Misconfigurations

#### Overly Permissive Rules
**Problem**: Security groups allowing too much access
```bash
# Find security groups allowing 0.0.0.0/0
aws ec2 describe-security-groups \
  --query 'SecurityGroups[?IpPermissions[?IpRanges[?CidrIp==`0.0.0.0/0`]]]'

# Audit security group rules
aws ec2 describe-security-groups \
  --query 'SecurityGroups[*].[GroupId,GroupName,IpPermissions[*].[IpProtocol,FromPort,ToPort,IpRanges[*].CidrIp]]' \
  --output table
```

## Performance Problems

### High Response Times

#### Application Latency
**Problem**: Slow API responses
```bash
# Check ALB target response times
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --dimensions Name=LoadBalancer,Value=app/infraprime-alb/50dc6c495c0c9188 \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 300 \
  --statistics Average,Maximum

# Check ECS service CPU/Memory utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=infraprime-backend Name=ClusterName,Value=infraprime-cluster \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 300 \
  --statistics Average
```

#### Database Performance
**Problem**: Slow database queries
```sql
-- Enable query logging (PostgreSQL)
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_min_duration_statement = 1000; -- Log queries > 1 second
SELECT pg_reload_conf();

-- Find slow queries
SELECT query, calls, total_time, mean_time, stddev_time
FROM pg_stat_statements
WHERE mean_time > 1000  -- Queries with mean time > 1 second
ORDER BY total_time DESC
LIMIT 20;

-- Check for missing indexes
SELECT schemaname, tablename, attname, n_distinct, correlation
FROM pg_stats
WHERE schemaname = 'public'
  AND n_distinct > 100
  AND correlation < 0.1;
```

## Debugging Tools

### AWS CLI Debug Mode
```bash
# Enable debug output
aws --debug ec2 describe-instances

# Use specific log level
export AWS_CLI_FILE_ENCODING=UTF-8
aws --cli-read-timeout 0 --cli-connect-timeout 60 ec2 describe-instances
```

### ECS Debug Commands
```bash
# Get detailed task information
aws ecs describe-tasks \
  --cluster infraprime-cluster \
  --tasks <task-arn> \
  --include TAGS

# Stream logs in real-time
aws logs tail /ecs/infraprime-backend --follow

# Run debug container
aws ecs run-task \
  --cluster infraprime-cluster \
  --task-definition infraprime-debug \
  --network-configuration '{
    "awsvpcConfiguration": {
      "subnets": ["subnet-12345"],
      "securityGroups": ["sg-12345"],
      "assignPublicIp": "ENABLED"
    }
  }'
```

### Database Debug Queries
```sql
-- Check active connections
SELECT pid, usename, application_name, client_addr, state, query_start, query
FROM pg_stat_activity
WHERE state = 'active';

-- Check table sizes
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;
```

### Network Debug Tools
```bash
# Test connectivity from container
docker run --rm -it amazonlinux:latest bash
yum install -y telnet curl postgresql

# Test database connectivity
telnet rds-endpoint 5432

# Test HTTP endpoints
curl -v https://api-endpoint/health

# DNS resolution
nslookup api-endpoint
```

## Emergency Procedures

### Application Rollback
```bash
# Quick rollback to previous version
aws ecs update-service \
  --cluster infraprime-cluster \
  --service infraprime-backend-service \
  --task-definition infraprime-backend:PREVIOUS_REVISION

# Or use blue-green deployment rollback
./scripts/rollback.sh
```

### Database Recovery
```bash
# Restore from latest automated snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier infraprime-db-restored \
  --db-snapshot-identifier $(aws rds describe-db-snapshots \
    --db-instance-identifier infraprime-db \
    --query 'DBSnapshots[0].DBSnapshotIdentifier' \
    --output text)
```

### Emergency Scaling
```bash
# Scale up immediately
aws ecs update-service \
  --cluster infraprime-cluster \
  --service infraprime-backend-service \
  --desired-count 10

# Scale database up
aws rds modify-db-instance \
  --db-instance-identifier infraprime-db \
  --db-instance-class db.t3.large \
  --apply-immediately
```

## Contact Information

### Escalation Path
1. **On-call Engineer**: Check runbook first
2. **Senior Engineer**: For complex infrastructure issues
3. **AWS Support**: For AWS service-specific problems
4. **Manager**: For critical business impact

### Emergency Contacts
- **Primary On-call**: [Your contact]
- **Secondary On-call**: [Backup contact]
- **AWS Support Case**: [Support plan details]
- **Infrastructure Team**: [Team contact]

---

**Remember**: Always check CloudWatch metrics and logs first. Most issues can be diagnosed through monitoring data before requiring access to individual resources.
