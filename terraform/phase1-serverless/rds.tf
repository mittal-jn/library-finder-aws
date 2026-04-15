# LibraryFinder Phase 1 - RDS PostgreSQL
# Managed database for application data

# ==========================================
# RDS Parameter Group
# ==========================================

resource "aws_db_parameter_group" "postgres" {
  name        = "${var.project_name}-postgres-params-${var.environment}"
  family      = "postgres15"  # Match your PostgreSQL version
  description = "Custom parameter group for LibraryFinder PostgreSQL"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = {
    Name = "${var.project_name}-postgres-params-${var.environment}"
  }
}

# ==========================================
# RDS Instance
# ==========================================

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db-${var.environment}"

  # Engine Configuration
  engine         = "postgres"
  engine_version = "15.8"  # Latest stable PostgreSQL 15
  instance_class = var.db_instance_class

  # Storage Configuration
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2  # Auto-scaling up to 2x
  storage_type          = "gp3"  # Latest generation, better performance
  storage_encrypted     = var.enable_rds_encryption

  # Database Configuration
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false  # NEVER expose database publicly

  # High Availability
  multi_az               = var.enable_multi_az_rds
  availability_zone      = var.enable_multi_az_rds ? null : var.availability_zones[0]

  # Backup Configuration
  backup_retention_period = var.db_backup_retention_days
  backup_window          = "03:00-04:00"  # 3-4 AM UTC
  maintenance_window     = "sun:04:00-sun:05:00"  # Sunday 4-5 AM UTC
  
  # Skip final snapshot for dev (change to false for production!)
  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.project_name}-db-final-snapshot-${var.environment}"
  
  # Delete protection (disabled for dev, enable for production!)
  deletion_protection = false

  # Monitoring
  enabled_cloudwatch_logs_exports = var.enable_cloudwatch_logs ? ["postgresql", "upgrade"] : []
  monitoring_interval             = var.enable_detailed_monitoring ? 60 : 0
  monitoring_role_arn            = var.enable_detailed_monitoring ? aws_iam_role.rds_monitoring[0].arn : null

  # Performance Insights (free for db.t3.micro!)
  performance_insights_enabled    = true
  performance_insights_retention_period = 7  # Free tier = 7 days

  # Parameter Group
  parameter_group_name = aws_db_parameter_group.postgres.name

  # Auto minor version upgrades
  auto_minor_version_upgrade = true

  # Prevent accidental deletion during terraform destroy
  # (Comment this out when you want to destroy for real)
  lifecycle {
    prevent_destroy = false  # Set to true for production
  }

  tags = {
    Name = "${var.project_name}-database-${var.environment}"
  }

  depends_on = [aws_db_subnet_group.main]
}

# ==========================================
# IAM Role for Enhanced Monitoring
# ==========================================

resource "aws_iam_role" "rds_monitoring" {
  count = var.enable_detailed_monitoring ? 1 : 0
  
  name = "${var.project_name}-rds-monitoring-role-${var.environment}"

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
    Name = "${var.project_name}-rds-monitoring-role-${var.environment}"
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.enable_detailed_monitoring ? 1 : 0
  
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
