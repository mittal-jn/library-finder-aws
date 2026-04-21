# =============================================================================
# Phase 4: CloudWatch Monitoring & Alarms
# =============================================================================
# 5 alarms (3 Lambda + 2 API Gateway v2) routed through SNS to email.
# Updated for API Gateway v2 (HTTP API).
# =============================================================================

locals {
  lambda_function_name = aws_lambda_function.search_api.function_name
  lambda_timeout_ms    = aws_lambda_function.search_api.timeout * 1000

  # API Gateway v2 (HTTP API) — uses ApiId, not ApiName
  api_gateway_id    = aws_apigatewayv2_api.search_api.id
  api_gateway_stage = aws_apigatewayv2_stage.api.name

  alarm_prefix = "library-finder-dev"
}

# -----------------------------------------------------------------------------
# SNS TOPIC — receives all alarm notifications
# -----------------------------------------------------------------------------
resource "aws_sns_topic" "alarms" {
  name = "${local.alarm_prefix}-alarms"

  tags = {
    Project = "library-finder-aws"
    Phase   = "4-monitoring"
  }
}

resource "aws_sns_topic_subscription" "alarms_email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# -----------------------------------------------------------------------------
# LAMBDA ALARMS (3)
# -----------------------------------------------------------------------------

# 1. Lambda errors > 0 in a 5-min window
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${local.alarm_prefix}-lambda-errors"
  alarm_description   = "search-api Lambda is throwing errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = local.lambda_function_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# 2. Lambda duration approaching timeout (80% of configured timeout)
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${local.alarm_prefix}-lambda-duration-high"
  alarm_description   = "search-api Lambda duration is approaching timeout"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = local.lambda_timeout_ms * 0.8
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = local.lambda_function_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# 3. Lambda throttles > 0 (concurrency limit being hit)
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${local.alarm_prefix}-lambda-throttles"
  alarm_description   = "search-api Lambda is being throttled"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = local.lambda_function_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# -----------------------------------------------------------------------------
# API GATEWAY v2 ALARMS (2)
# -----------------------------------------------------------------------------

# 4. API Gateway 5xx error rate > 1%
resource "aws_cloudwatch_metric_alarm" "api_5xx_errors" {
  alarm_name          = "${local.alarm_prefix}-api-5xx-rate"
  alarm_description   = "API Gateway 5xx error rate exceeds 1%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 1
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "error_rate"
    expression  = "(errors / requests) * 100"
    label       = "5xx Error Rate (%)"
    return_data = true
  }

  metric_query {
    id = "errors"
    metric {
      metric_name = "5xx"
      namespace   = "AWS/ApiGateway"
      period      = 300
      stat        = "Sum"
      dimensions = {
        ApiId = local.api_gateway_id
        Stage = local.api_gateway_stage
      }
    }
  }

  metric_query {
    id = "requests"
    metric {
      metric_name = "Count"
      namespace   = "AWS/ApiGateway"
      period      = 300
      stat        = "Sum"
      dimensions = {
        ApiId = local.api_gateway_id
        Stage = local.api_gateway_stage
      }
    }
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# 5. API Gateway p95 latency > 2 seconds
resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "${local.alarm_prefix}-api-latency-p95"
  alarm_description   = "API Gateway p95 latency exceeds 2 seconds"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  extended_statistic  = "p95"
  threshold           = 2000
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = local.api_gateway_id
    Stage = local.api_gateway_stage
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# -----------------------------------------------------------------------------
# OUTPUTS
# -----------------------------------------------------------------------------
output "sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  value       = aws_sns_topic.alarms.arn
}

output "alarm_names" {
  description = "All CloudWatch alarms created in Phase 4"
  value = [
    aws_cloudwatch_metric_alarm.lambda_errors.alarm_name,
    aws_cloudwatch_metric_alarm.lambda_duration.alarm_name,
    aws_cloudwatch_metric_alarm.lambda_throttles.alarm_name,
    aws_cloudwatch_metric_alarm.api_5xx_errors.alarm_name,
    aws_cloudwatch_metric_alarm.api_latency.alarm_name,
  ]
}
