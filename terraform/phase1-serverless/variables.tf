# LibraryFinder Phase 1 - Variables
# All configurable parameters for the infrastructure

# ==========================================
# General Configuration
# ==========================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "library-finder"
}

# ==========================================
# VPC Configuration
# ==========================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for multi-AZ deployment"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# ==========================================
# RDS Configuration
# ==========================================

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"  # Cost-optimized: ~$15/month
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "libraryfinder"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password (must be 8+ characters)"
  type        = string
  sensitive   = true
  # Set via: export TF_VAR_db_password="YourSecurePassword123!"
  # Or in terraform.tfvars (don't commit!)
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20  # Minimum for gp3
}

variable "db_backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

# ==========================================
# Lambda Configuration
# ==========================================

variable "lambda_runtime" {
  description = "Lambda runtime version"
  type        = string
  default     = "nodejs20.x"  # Latest stable Node.js
}

variable "lambda_memory" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 256  # Adequate for database queries
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30  # Allow time for database operations
}

# ==========================================
# S3 Configuration
# ==========================================

variable "enable_s3_versioning" {
  description = "Enable versioning for S3 bucket"
  type        = bool
  default     = true
}

variable "s3_lifecycle_days" {
  description = "Days after which to transition objects to cheaper storage"
  type        = number
  default     = 90
}

# ==========================================
# Feature Flags (Cost Control)
# ==========================================

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access (costs ~$30/month)"
  type        = bool
  default     = false  # Save cost - Lambda can use VPC endpoints instead
}

variable "enable_multi_az_rds" {
  description = "Enable Multi-AZ for RDS high availability (costs ~2x)"
  type        = bool
  default     = false  # Single-AZ for dev/demo
}

variable "enable_rds_encryption" {
  description = "Enable encryption at rest for RDS"
  type        = bool
  default     = true  # Security best practice
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch Logs for Lambda"
  type        = bool
  default     = true
}

# ==========================================
# Monitoring Configuration
# ==========================================

variable "alarm_email" {
  description = "Email address for CloudWatch alarms"
  type        = string
  default     = ""  # Set in terraform.tfvars
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring (1-min intervals)"
  type        = bool
  default     = false  # Basic monitoring (5-min) is usually sufficient
}

# ==========================================
# Tags
# ==========================================

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project   = "LibraryFinder"
    ManagedBy = "Terraform"
  }
}
