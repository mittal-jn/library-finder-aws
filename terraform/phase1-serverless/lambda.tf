# LibraryFinder Phase 1 - Database Setup Lambda
# Lambda function to create database tables and insert sample data

# ==========================================
# IAM Role for Lambda
# ==========================================

resource "aws_iam_role" "lambda_db_setup" {
  name = "${var.project_name}-lambda-db-setup-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-lambda-db-setup-role-${var.environment}"
  }
}

# ==========================================
# IAM Policy for Lambda VPC Access
# ==========================================

resource "aws_iam_role_policy_attachment" "lambda_db_setup_vpc" {
  role       = aws_iam_role.lambda_db_setup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# ==========================================
# IAM Policy for CloudWatch Logs
# ==========================================

resource "aws_iam_role_policy_attachment" "lambda_db_setup_logs" {
  role       = aws_iam_role.lambda_db_setup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ==========================================
# Lambda Function - Database Setup
# ==========================================

resource "aws_lambda_function" "db_setup" {
  filename      = "${path.module}/lambda-db-setup.zip"
  function_name = "${var.project_name}-db-setup-${var.environment}"
  role          = aws_iam_role.lambda_db_setup.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 60 # Database operations can take time
  memory_size   = 256

  # VPC Configuration - allows Lambda to access RDS
  vpc_config {
    subnet_ids         = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  # Environment variables for database connection
  environment {
    variables = {
      DB_HOST     = aws_db_instance.main.address
      DB_PORT     = aws_db_instance.main.port
      DB_NAME     = aws_db_instance.main.db_name
      DB_USER     = var.db_username
      DB_PASSWORD = var.db_password
    }
  }

  # Ensure IAM role is created first
  depends_on = [
    aws_iam_role_policy_attachment.lambda_db_setup_vpc,
    aws_iam_role_policy_attachment.lambda_db_setup_logs,
    aws_db_instance.main
  ]

  tags = {
    Name = "${var.project_name}-db-setup-${var.environment}"
  }
}

# ==========================================
# CloudWatch Log Group for Lambda
# ==========================================

resource "aws_cloudwatch_log_group" "lambda_db_setup" {
  name              = "/aws/lambda/${aws_lambda_function.db_setup.function_name}"
  retention_in_days = 7 # Keep logs for 7 days (free tier)

  tags = {
    Name = "${var.project_name}-lambda-db-setup-logs-${var.environment}"
  }
}
