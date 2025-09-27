# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group-${var.environment}"
  subnet_ids = var.database_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group-${var.environment}"
    Type = "DB Subnet Group"
  }
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  family = "postgres15"
  name   = "${var.project_name}-db-params-${var.environment}"

  # Optimize for performance and monitoring
  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000" # Log queries taking more than 1 second
  }

  parameter {
    name  = "log_line_prefix"
    value = "%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h "
  }

  parameter {
    name  = "log_checkpoints"
    value = "1"
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_lock_waits"
    value = "1"
  }

  # Performance tuning
  parameter {
    name  = "shared_buffers"
    value = "{DBInstanceClassMemory/4}"
  }

  parameter {
    name  = "effective_cache_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  tags = {
    Name = "${var.project_name}-db-params-${var.environment}"
    Type = "DB Parameter Group"
  }
}

# RDS Option Group (if needed for specific features)
resource "aws_db_option_group" "main" {
  name                     = "${var.project_name}-db-options-${var.environment}"
  option_group_description = "Option group for ${var.project_name} ${var.environment}"
  engine_name              = "postgres"
  major_engine_version     = "15"

  tags = {
    Name = "${var.project_name}-db-options-${var.environment}"
    Type = "DB Option Group"
  }
}

# Random password for DB (if not managed by RDS)
resource "random_password" "db_password" {
  count   = var.manage_password ? 0 : 1
  length  = 16
  special = true
}

# RDS Instance
resource "aws_db_instance" "main" {
  # Basic Configuration
  identifier     = "${var.project_name}-db-${var.environment}"
  engine         = "postgres"
  engine_version = var.postgres_version
  instance_class = var.db_instance_class

  # Storage Configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true
  kms_key_id            = var.kms_key_id

  # Database Configuration
  db_name  = var.database_name
  username = var.database_username
  password = var.manage_password ? null : (
    var.database_password != null ? var.database_password : random_password.db_password[0].result
  )
  manage_master_user_password = var.manage_password

  # Network Configuration
  vpc_security_group_ids = [var.database_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  publicly_accessible    = false
  port                   = 5432

  # Parameter and Option Groups
  parameter_group_name = aws_db_parameter_group.main.name
  option_group_name    = aws_db_option_group.main.name

  # Backup Configuration
  backup_retention_period  = var.backup_retention_period
  backup_window            = var.backup_window
  copy_tags_to_snapshot    = true
  delete_automated_backups = var.environment != "prod"

  # Maintenance Configuration
  maintenance_window         = var.maintenance_window
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.environment != "prod"

  # High Availability
  multi_az          = var.multi_az
  availability_zone = var.multi_az ? null : var.availability_zone

  # Monitoring and Logging
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.kms_key_id : null

  enabled_cloudwatch_logs_exports = [
    "postgresql"
  ]

  # Security and Compliance
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-final-snapshot-${var.environment}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Lifecycle
  lifecycle {
    ignore_changes = [
      password,
      final_snapshot_identifier
    ]
    prevent_destroy = false # Set to true for production
  }

  tags = {
    Name            = "${var.project_name}-database-${var.environment}"
    Type            = "RDS Instance"
    Engine          = "PostgreSQL"
    BackupRetention = var.backup_retention_period
  }
}

# Enhanced Monitoring IAM Role
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0
  name  = "${var.project_name}-rds-enhanced-monitoring-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-rds-enhanced-monitoring-${var.environment}"
    Type = "RDS Enhanced Monitoring Role"
  }
}

# Attach AWS managed policy for RDS enhanced monitoring
resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count      = var.monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Read Replica (for production environments)
resource "aws_db_instance" "replica" {
  count = var.create_read_replica ? 1 : 0

  identifier                 = "${var.project_name}-db-replica-${var.environment}"
  replicate_source_db        = aws_db_instance.main.identifier
  instance_class             = var.replica_instance_class
  publicly_accessible        = false
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # Monitoring
  monitoring_interval          = var.monitoring_interval
  monitoring_role_arn          = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
  performance_insights_enabled = var.performance_insights_enabled

  tags = {
    Name   = "${var.project_name}-database-replica-${var.environment}"
    Type   = "RDS Read Replica"
    Engine = "PostgreSQL"
  }
}

# CloudWatch Log Group for PostgreSQL logs
resource "aws_cloudwatch_log_group" "postgresql" {
  name              = "/aws/rds/instance/${aws_db_instance.main.identifier}/postgresql"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  tags = {
    Name = "${var.project_name}-db-logs-${var.environment}"
    Type = "CloudWatch Log Group"
  }
}

# SSM Parameters for database connection (non-sensitive values)
resource "aws_ssm_parameter" "database_endpoint" {
  name  = "/${var.project_name}/${var.environment}/database/endpoint"
  type  = "String"
  value = aws_db_instance.main.endpoint

  tags = {
    Name = "${var.project_name}-db-endpoint-${var.environment}"
    Type = "SSM Parameter"
  }
}

resource "aws_ssm_parameter" "database_port" {
  name  = "/${var.project_name}/${var.environment}/database/port"
  type  = "String"
  value = tostring(aws_db_instance.main.port)

  tags = {
    Name = "${var.project_name}-db-port-${var.environment}"
    Type = "SSM Parameter"
  }
}

resource "aws_ssm_parameter" "database_name" {
  name  = "/${var.project_name}/${var.environment}/database/name"
  type  = "String"
  value = aws_db_instance.main.db_name

  tags = {
    Name = "${var.project_name}-db-name-${var.environment}"
    Type = "SSM Parameter"
  }
}
