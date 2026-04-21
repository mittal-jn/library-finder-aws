# Lambda function for searching libraries
# This Lambda queries RDS and returns JSON results via HTTPS endpoint

# IAM role for search Lambda
resource "aws_iam_role" "lambda_search_api" {
  name = "${var.project_name}-lambda-search-api-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-lambda-search-api-role-${var.environment}"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Attach VPC access policy (needed to access RDS in private subnet)
resource "aws_iam_role_policy_attachment" "lambda_search_api_vpc" {
  role       = aws_iam_role.lambda_search_api.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Attach basic execution policy (for CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_search_api_basic" {
  role       = aws_iam_role.lambda_search_api.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# CloudWatch Log Group for search Lambda
resource "aws_cloudwatch_log_group" "lambda_search_api" {
  name              = "/aws/lambda/${var.project_name}-search-api-${var.environment}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-lambda-search-api-logs-${var.environment}"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Lambda function for search API
resource "aws_lambda_function" "search_api" {
  filename      = "${path.module}/lambda-search-api.zip"
  function_name = "${var.project_name}-search-api-${var.environment}"
  role          = aws_iam_role.lambda_search_api.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 256

  source_code_hash = filebase64sha256("${path.module}/lambda-search-api.zip")

  # VPC configuration - same as db-setup Lambda
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

  depends_on = [
    aws_cloudwatch_log_group.lambda_search_api,
    aws_iam_role_policy_attachment.lambda_search_api_vpc,
    aws_iam_role_policy_attachment.lambda_search_api_basic
  ]

  tags = {
    Name        = "${var.project_name}-search-api-${var.environment}"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Lambda Function URL - provides HTTPS endpoint
# API Gateway v2 (HTTP API)
resource "aws_apigatewayv2_api" "search_api" {
  name          = "${var.project_name}-search-api-${var.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins  = ["*"]
    allow_methods  = ["GET", "POST", "OPTIONS"]
    allow_headers  = ["*"]
    expose_headers = ["*"]
    max_age        = 86400
  }

  tags = {
    Name      = "${var.project_name}-search-api-${var.environment}"
    ManagedBy = "Terraform"
  }
}

# Lambda integration
resource "aws_apigatewayv2_integration" "search_api" {
  api_id                 = aws_apigatewayv2_api.search_api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = "2.0"
  integration_uri        = aws_lambda_function.search_api.arn
}

# Routes
resource "aws_apigatewayv2_route" "root" {
  api_id    = aws_apigatewayv2_api.search_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.search_api.id}"
}

# Deployment stage
resource "aws_apigatewayv2_stage" "api" {
  api_id      = aws_apigatewayv2_api.search_api.id
  name        = var.environment
  auto_deploy = true
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.search_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.search_api.execution_arn}/*/*"
}

# Outputs
output "search_api_url" {
  description = "HTTPS endpoint for search API via API Gateway"
  value       = aws_apigatewayv2_stage.api.invoke_url
}

output "search_api_function_name" {
  description = "Lambda function name for search API"
  value       = aws_lambda_function.search_api.function_name
}

output "search_api_function_arn" {
  description = "Lambda function ARN for search API"
  value       = aws_lambda_function.search_api.arn
}