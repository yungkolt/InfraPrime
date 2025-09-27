# InfraPrime Security Documentation

## Table of Contents
1. [Security Architecture](#security-architecture)
2. [Authentication & Authorization](#authentication--authorization)
3. [Data Protection](#data-protection)
4. [Network Security](#network-security)
5. [Infrastructure Security](#infrastructure-security)
6. [Application Security](#application-security)
7. [Monitoring & Incident Response](#monitoring--incident-response)
8. [Compliance](#compliance)

## Security Architecture

### Defense in Depth Strategy
InfraPrime implements multiple layers of security controls:

```
┌─────────────────────────────────────────┐
│                WAF/CDN                  │ ← DDoS, Bot Protection
├─────────────────────────────────────────┤
│            Load Balancer                │ ← SSL Termination
├─────────────────────────────────────────┤
│          Application Layer              │ ← Input Validation, OWASP
├─────────────────────────────────────────┤
│         Container Security              │ ← Image Scanning, Runtime
├─────────────────────────────────────────┤
│         Network Security                │ ← VPC, Security Groups
├─────────────────────────────────────────┤
│          Data Layer                     │ ← Encryption, Access Control
└─────────────────────────────────────────┘
```

### Security Principles
1. **Principle of Least Privilege**: Minimal required permissions
2. **Zero Trust**: Never trust, always verify
3. **Defense in Depth**: Multiple security layers
4. **Encryption Everywhere**: Data at rest and in transit
5. **Continuous Monitoring**: Real-time threat detection

## Authentication & Authorization

### IAM Configuration

#### Production IAM Roles
```json
{
  "ECSTaskExecutionRole": {
    "Description": "Allows ECS tasks to pull images and write logs",
    "Policies": [
      "AmazonECSTaskExecutionRolePolicy",
      "AmazonEC2ContainerRegistryReadOnly"
    ]
  },
  "ECSTaskRole": {
    "Description": "Runtime permissions for application containers",
    "Policies": [
      "CloudWatchMetricsPolicy",
      "SecretsManagerReadPolicy"
    ]
  },
  "GitHubActionsRole": {
    "Description": "CI/CD deployment permissions",
    "Policies": [
      "ECSDeploymentPolicy",
      "ECRPushPolicy",
      "TerraformStatePolicy"
    ]
  }
}
```

#### IAM Policy Examples
```json
// Application-specific S3 access
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::infraprime-uploads/*"
      ]
    }
  ]
}

// Database access via IAM
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rds-db:connect"
      ],
      "Resource": [
        "arn:aws:rds-db:us-east-1:123456789012:dbuser:infraprime-db/app_user"
      ]
    }
  ]
}
```

### Application Authentication

#### JWT Implementation
```python
# Backend authentication middleware
import jwt
from functools import wraps

def require_auth(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        
        try:
            payload = jwt.decode(
                token, 
                current_app.config['SECRET_KEY'], 
                algorithms=['HS256']
            )
            current_user = User.query.get(payload['user_id'])
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Invalid token'}), 401
            
        return f(current_user, *args, **kwargs)
    return decorated_function
```

#### Role-Based Access Control (RBAC)
```python
# User roles and permissions
class Role(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), unique=True)
    permissions = db.relationship('Permission', backref='role')

class Permission(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), unique=True)
    resource = db.Column(db.String(50))
    action = db.Column(db.String(50))

# Permission decorator
def require_permission(permission_name):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if not current_user.has_permission(permission_name):
                return jsonify({'error': 'Insufficient permissions'}), 403
            return f(*args, **kwargs)
        return decorated_function
    return decorator
```

## Data Protection

### Encryption at Rest

#### RDS Encryption
```hcl
# Terraform configuration
resource "aws_db_instance" "main" {
  storage_encrypted = true
  kms_key_id       = aws_kms_key.database.arn
  
  # Additional security settings
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  deletion_protection    = true
}

resource "aws_kms_key" "database" {
  description = "InfraPrime Database Encryption Key"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action = "kms:*"
        Resource = "*"
      }
    ]
  })
}
```

#### EBS Volume Encryption
```hcl
# All EBS volumes encrypted by default
resource "aws_ebs_encryption_by_default" "main" {
  enabled = true
}

resource "aws_ebs_default_kms_key" "main" {
  key_arn = aws_kms_key.ebs.arn
}
```

#### S3 Encryption
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}
```

### Encryption in Transit

#### Application Level TLS
```python
# Flask application SSL configuration
from flask_talisman import Talisman

app = Flask(__name__)

# Force HTTPS
Talisman(app, 
    force_https=True,
    strict_transport_security=True,
    strict_transport_security_max_age=31536000,
    content_security_policy={
        'default-src': "'self'",
        'script-src': "'self' 'unsafe-inline'",
        'style-src': "'self' 'unsafe-inline'"
    }
)
```

#### Database Connection Security
```python
# PostgreSQL SSL connection
DATABASE_URL = "postgresql://user:pass@host:5432/db?sslmode=require&sslcert=client-cert.pem&sslkey=client-key.pem&sslrootcert=ca-cert.pem"
```

### Secrets Management

#### AWS Secrets Manager Integration
```python
import boto3
import json

def get_secret(secret_name):
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name='us-east-1'
    )
    
    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
        secret = json.loads(get_secret_value_response['SecretString'])
        return secret
    except ClientError as e:
        logger.error(f"Failed to retrieve secret {secret_name}: {e}")
        raise e

# Usage in application
db_credentials = get_secret('infraprime/database/credentials')
DATABASE_URL = f"postgresql://{db_credentials['username']}:{db_credentials['password']}@{db_credentials['host']}:5432/{db_credentials['database']}"
```

#### Terraform Secrets Management
```hcl
# Store database password in Secrets Manager
resource "aws_secretsmanager_secret" "database_password" {
  name = "infraprime/database/credentials"
  
  replica {
    region = "us-west-2"  # Cross-region backup
  }
}

resource "aws_secretsmanager_secret_version" "database_password" {
  secret_id = aws_secretsmanager_secret.database_password.id
  secret_string = jsonencode({
    username = var.database_username
    password = var.database_password
    host     = aws_db_instance.main.endpoint
    database = var.database_name
  })
}
```

## Network Security

### VPC Security Architecture
```hcl
# VPC with private and public subnets
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "infraprime-vpc"
  }
}

# Internet Gateway for public subnets
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# NAT Gateway for private subnet internet access
resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  depends_on = [aws_internet_gateway.main]
}
```

### Security Groups Configuration
```hcl
# ALB Security Group - Internet facing
resource "aws_security_group" "alb" {
  name_prefix = "infraprime-alb-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Tasks Security Group - Private
resource "aws_security_group" "ecs_tasks" {
  name_prefix = "infraprime-ecs-tasks-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Database Security Group - Most restrictive
resource "aws_security_group" "database" {
  name_prefix = "infraprime-database-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }
  
  # No egress rules - database doesn't need outbound access
}
```

### Network ACLs
```hcl
# Private subnet NACL - Additional layer of security
resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.main.id

  # Allow inbound HTTP/HTTPS from public subnets
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.1.0/24"  # Public subnet CIDR
    from_port  = 80
    to_port    = 443
  }

  # Allow return traffic
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "infraprime-private-nacl"
  }
}
```

### WAF Configuration
```hcl
resource "aws_wafv2_web_acl" "main" {
  name  = "infraprime-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Rate limiting rule
  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Core Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }
}
```

## Infrastructure Security

### Container Security

#### Dockerfile Security Best Practices
```dockerfile
# Use specific, minimal base image
FROM python:3.11-slim-bullseye

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Copy requirements first (better caching)
COPY requirements.txt .

# Install dependencies as root, then switch user
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    rm -rf /root/.cache

# Copy application code
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

# Use specific port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5000/health || exit 1

# Start application
CMD ["python", "app.py"]
```

#### Container Image Scanning
```yaml
# GitHub Actions security scanning
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: '${{ env.ECR_REGISTRY }}/infraprime-backend:${{ github.sha }}'
    format: 'sarif'
    output: 'trivy-results.sarif'

- name: Upload Trivy scan results to GitHub Security tab
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: 'trivy-results.sarif'
```

### EC2 Security (if used)

#### Instance Hardening
```bash
#!/bin/bash
# EC2 instance hardening script

# Update system
yum update -y

# Install security tools
yum install -y fail2ban aide

# Configure fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# Disable unused services
systemctl disable telnet
systemctl disable ftp

# Configure SSH security
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Enable firewall
systemctl enable iptables
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -j DROP
service iptables save
```

### ECS Security Configuration
```hcl
resource "aws_ecs_cluster" "main" {
  name = "infraprime-cluster"

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.ecs.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_exec.name
      }
    }
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ECS task definition with security context
resource "aws_ecs_task_definition" "backend" {
  family                   = "infraprime-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn           = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = "${aws_ecr_repository.backend.repository_url}:latest"
      
      # Security: Run as non-root user
      user = "1000:1000"
      
      # Security: Read-only root filesystem
      readonlyRootFilesystem = true
      
      # Security: Drop all capabilities
      linuxParameters = {
        capabilities = {
          drop = ["ALL"]
        }
      }
      
      # Logging configuration
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "backend"
        }
      }
    }
  ])
}
```

## Application Security

### Input Validation and Sanitization
```python
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from marshmallow import Schema, fields, validate, ValidationError
import bleach

# Rate limiting
limiter = Limiter(
    app,
    key_func=get_remote_address,
    default_limits=["1000 per hour"]
)

# Input validation schemas
class UserCreateSchema(Schema):
    username = fields.Str(
        required=True,
        validate=[
            validate.Length(min=3, max=50),
            validate.Regexp(r'^[a-zA-Z0-9_]+$', error="Invalid characters")
        ]
    )
    email = fields.Email(required=True)
    password = fields.Str(
        required=True,
        validate=validate.Length(min=8, max=128)
    )

# Input sanitization
def sanitize_input(data):
    if isinstance(data, str):
        return bleach.clean(data, tags=[], strip=True)
    return data

# API endpoint with validation
@app.route('/api/users', methods=['POST'])
@limiter.limit("5 per minute")
def create_user():
    try:
        schema = UserCreateSchema()
        user_data = schema.load(request.json)
        
        # Sanitize inputs
        user_data = {k: sanitize_input(v) for k, v in user_data.items()}
        
        # Create user logic here
        
        return jsonify({'message': 'User created successfully'}), 201
        
    except ValidationError as err:
        return jsonify({'errors': err.messages}), 400
```

### SQL Injection Prevention
```python
from sqlalchemy.text import text

# ✅ GOOD: Parameterized query
def get_user_by_id(user_id):
    query = text("SELECT * FROM users WHERE id = :user_id")
    result = db.session.execute(query, {'user_id': user_id})
    return result.fetchone()

# ✅ GOOD: ORM usage
def get_users_by_role(role_name):
    return User.query.filter(User.role == role_name).all()

# ❌ BAD: String concatenation (vulnerable to SQL injection)
def get_user_bad(user_id):
    query = f"SELECT * FROM users WHERE id = {user_id}"  # DON'T DO THIS
    result = db.session.execute(query)
    return result.fetchone()
```

### Cross-Site Scripting (XSS) Prevention
```python
from flask import escape
from markupsafe import Markup
import bleach

# Content Security Policy
@app.after_request
def set_csp_header(response):
    response.headers['Content-Security-Policy'] = (
        "default-src 'self'; "
        "script-src 'self' 'unsafe-inline'; "
        "style-src 'self' 'unsafe-inline'; "
        "img-src 'self' data: https:; "
        "font-src 'self' https:; "
        "connect-src 'self' https:; "
        "frame-ancestors 'none';"
    )
    return response

# HTML sanitization
def safe_html(content):
    allowed_tags = ['p', 'br', 'strong', 'em', 'ul', 'ol', 'li']
    return bleach.clean(content, tags=allowed_tags, strip=True)

# Template auto-escaping (Jinja2 does this by default)
@app.route('/user/<int:user_id>')
def show_user(user_id):
    user = User.query.get_or_404(user_id)
    # Jinja2 will automatically escape user.name
    return render_template('user.html', user=user)
```

### Cross-Site Request Forgery (CSRF) Protection
```python
from flask_wtf.csrf import CSRFProtect
from flask_wtf import FlaskForm

# Enable CSRF protection
csrf = CSRFProtect(app)

# API endpoints with CSRF exemption (use JWT instead)
@app.route('/api/data', methods=['POST'])
@csrf.exempt
def api_endpoint():
    # Verify JWT token instead of CSRF
    token = request.headers.get('Authorization')
    if not verify_jwt_token(token):
        return jsonify({'error': 'Invalid token'}), 401
    
    return jsonify({'message': 'Success'})
```

## Monitoring & Incident Response

### Security Monitoring

#### CloudTrail Configuration
```hcl
resource "aws_cloudtrail" "main" {
  name           = "infraprime-cloudtrail"
  s3_bucket_name = aws_s3_bucket.cloudtrail.bucket
  
  # Enable log file validation
  enable_log_file_validation = true
  
  # Include global services
  include_global_service_events = true
  is_multi_region_trail        = true
  
  # Enable insights
  insight_selector {
    insight_type = "ApiCallRateInsight"
  }

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    exclude_management_event_sources = []

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.main.arn}/*"]
    }
  }
}
```

#### VPC Flow Logs
```hcl
resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

resource "aws_cloudwatch_log_group" "vpc_flow" {
  name              = "/aws/vpc/flowlogs"
  retention_in_days = 14
}
```

#### Security Alerts
```hcl
# CloudWatch alarms for security events
resource "aws_cloudwatch_metric_alarm" "failed_logins" {
  alarm_name          = "high-failed-login-attempts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "failed_login_attempts"
  namespace           = "InfraPrime/Security"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors failed login attempts"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "root_access" {
  alarm_name          = "root-access-detected"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "RootAccess"
  namespace           = "AWS/CloudTrail"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alert when root user is used"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}
```

### Incident Response

#### Security Incident Playbook
1. **Detection & Analysis**
   - Review CloudWatch alerts
   - Check CloudTrail logs
   - Analyze VPC Flow Logs
   - Review application logs

2. **Containment**
   - Isolate affected resources
   - Revoke compromised credentials
   - Block malicious IP addresses
   - Scale down affected services if needed

3. **Eradication**
   - Remove malware/backdoors
   - Patch vulnerabilities
   - Update security groups
   - Rotate credentials

4. **Recovery**
   - Restore from clean backups
   - Monitor for reinfection
   - Gradually restore services
   - Update documentation

5. **Lessons Learned**
   - Document incident timeline
   - Update security procedures
   - Implement additional controls
   - Train team on new procedures

#### Automated Response
```python
# Lambda function for automated incident response
import boto3
import json

def lambda_handler(event, context):
    """
    Automated response to security incidents
    """
    # Parse CloudWatch alarm
    alarm_data = json.loads(event['Records'][0]['Sns']['Message'])
    
    if alarm_data['AlarmName'] == 'high-failed-login-attempts':
        # Block suspicious IP addresses
        block_suspicious_ips(alarm_data)
    
    elif alarm_data['AlarmName'] == 'root-access-detected':
        # Send high-priority alert
        send_security_alert(alarm_data, priority='HIGH')
    
    return {'statusCode': 200}

def block_suspicious_ips(alarm_data):
    """Block IPs with high failed login attempts"""
    waf = boto3.client('wafv2')
    
    # Add IP to WAF block list
    # Implementation details...
    
def send_security_alert(alarm_data, priority='MEDIUM'):
    """Send security alert to incident response team"""
    sns = boto3.client('sns')
    
    message = f"""
    SECURITY ALERT - Priority: {priority}
    
    Alarm: {alarm_data['AlarmName']}
    Description: {alarm_data['AlarmDescription']}
    Time: {alarm_data['StateChangeTime']}
    
    Please investigate immediately.
    """
    
    sns.publish(
        TopicArn='arn:aws:sns:us-east-1:123456789012:security-alerts',
        Message=message,
        Subject=f'Security Alert: {alarm_data["AlarmName"]}'
    )
```

## Compliance

### Data Privacy (GDPR/CCPA)
```python
# Data retention and deletion
class DataRetentionManager:
    def __init__(self):
        self.retention_periods = {
            'user_sessions': 30,  # days
            'access_logs': 90,
            'audit_logs': 2555,  # 7 years
            'user_data': None     # Keep until deletion request
        }
    
    def schedule_data_deletion(self, data_type, created_date):
        """Schedule automatic data deletion"""
        if data_type in self.retention_periods:
            retention_days = self.retention_periods[data_type]
            if retention_days:
                deletion_date = created_date + timedelta(days=retention_days)
                # Schedule deletion job
                
    def handle_deletion_request(self, user_id):
        """Handle GDPR Article 17 - Right to erasure"""
        # Anonymize or delete personal data
        user = User.query.get(user_id)
        if user:
            # Keep audit trail but remove PII
            user.email = f"deleted_user_{user.id}@deleted.local"
            user.name = "Deleted User"
            user.phone = None
            user.address = None
            db.session.commit()
            
            # Delete related data
            UserSession.query.filter_by(user_id=user_id).delete()
            db.session.commit()
```

### SOC 2 Compliance

#### Access Controls
```python
# Audit logging for all data access
from functools import wraps
import logging

audit_logger = logging.getLogger('audit')

def audit_data_access(resource_type):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            user_id = getattr(current_user, 'id', 'anonymous')
            
            audit_logger.info({
                'event': 'data_access',
                'user_id': user_id,
                'resource_type': resource_type,
                'function': f.__name__,
                'timestamp': datetime.utcnow().isoformat(),
                'ip_address': request.remote_addr
            })
            
            return f(*args, **kwargs)
        return decorated_function
    return decorator

# Usage
@app.route('/api/users/<int:user_id>')
@require_auth
@audit_data_access('user_data')
def get_user(user_id):
    return User.query.get_or_404(user_id)
```

### Security Audit Checklist

#### Infrastructure Security
- [ ] All data encrypted at rest and in transit
- [ ] VPC properly configured with private subnets
- [ ] Security groups follow least privilege
- [ ] WAF enabled with appropriate rules
- [ ] CloudTrail enabled in all regions
- [ ] VPC Flow Logs enabled
- [ ] GuardDuty enabled for threat detection
- [ ] Config enabled for compliance monitoring

#### Application Security
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention measures
- [ ] XSS protection implemented
- [ ] CSRF protection enabled
- [ ] Authentication and authorization working
- [ ] Secrets properly managed
- [ ] Error messages don't leak information
- [ ] Security headers configured

#### Operational Security
- [ ] Regular security assessments performed
- [ ] Incident response plan documented
- [ ] Security monitoring and alerting active
- [ ] Access reviews conducted quarterly
- [ ] Security training completed by team
- [ ] Backup and recovery procedures tested
- [ ] Patch management process in place
- [ ] Vulnerability scanning automated

---

**Remember**: Security is not a one-time implementation but an ongoing process. Regularly review and update security measures as threats evolve and the application grows.
