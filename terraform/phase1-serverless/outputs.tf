# LibraryFinder Phase 1 - Outputs
# Important values displayed after terraform apply

# ==========================================
# VPC Outputs
# ==========================================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

# ==========================================
# S3 Outputs
# ==========================================

output "s3_bucket_name" {
  description = "S3 bucket name for frontend"
  value       = aws_s3_bucket.frontend.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.frontend.arn
}

output "s3_website_endpoint" {
  description = "S3 website endpoint URL"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

output "s3_website_url" {
  description = "Full S3 website URL"
  value       = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
}

# ==========================================
# RDS Outputs
# ==========================================

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "RDS instance address (hostname)"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.main.db_name
}

output "rds_username" {
  description = "RDS master username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "rds_connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = "postgresql://${aws_db_instance.main.username}@${aws_db_instance.main.endpoint}/${aws_db_instance.main.db_name}"
  sensitive   = true
}

# ==========================================
# Security Group Outputs
# ==========================================

output "lambda_security_group_id" {
  description = "Security group ID for Lambda functions"
  value       = aws_security_group.lambda.id
}

output "rds_security_group_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds.id
}

# ==========================================
# Metadata Outputs
# ==========================================

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "random_suffix" {
  description = "Random suffix used for unique names"
  value       = random_id.suffix.hex
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

# ==========================================
# Cost Estimation
# ==========================================

output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown"
  value = {
    rds_instance     = "~$15/month (db.t3.micro)"
    s3_storage       = "<$1/month (under 5GB)"
    nat_gateway      = var.enable_nat_gateway ? "~$30/month (enabled)" : "$0 (disabled)"
    data_transfer    = "~$1-5/month (varies by usage)"
    cloudwatch       = "$0 (free tier)"
    total_min        = var.enable_nat_gateway ? "~$46/month" : "~$16/month"
    total_max        = var.enable_nat_gateway ? "~$51/month" : "~$21/month"
  }
}

# ==========================================
# Next Steps
# ==========================================

output "next_steps" {
  description = "What to do after infrastructure is deployed"
  value = <<-EOT
  
  ✅ Infrastructure deployed successfully!
  
  Next Steps:
  
  1. TEST DATABASE CONNECTION:
     psql -h ${aws_db_instance.main.address} -U ${aws_db_instance.main.username} -d ${aws_db_instance.main.db_name}
     (You'll be prompted for password)
  
  2. UPLOAD FRONTEND TO S3:
     cd ../../../frontend
     aws s3 sync . s3://${aws_s3_bucket.frontend.id}/ --exclude ".git/*"
  
  3. VIEW YOUR WEBSITE:
     http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}
  
  4. CREATE LAMBDA FUNCTION:
     (We'll do this in the next step)
  
  5. SET UP MONITORING:
     Check CloudWatch → Dashboards in AWS Console
  
  EOT
}

# ==========================================
# Quick Commands
# ==========================================

output "useful_commands" {
  description = "Useful AWS CLI commands for this infrastructure"
  value = {
    sync_frontend_to_s3    = "aws s3 sync ./frontend s3://${aws_s3_bucket.frontend.id}/"
    connect_to_database    = "psql -h ${aws_db_instance.main.address} -U ${aws_db_instance.main.username} -d ${aws_db_instance.main.db_name}"
    view_cloudwatch_logs   = "aws logs tail /aws/lambda/library-finder-search-api --follow"
    describe_rds_instance  = "aws rds describe-db-instances --db-instance-identifier ${aws_db_instance.main.identifier}"
  }
}
