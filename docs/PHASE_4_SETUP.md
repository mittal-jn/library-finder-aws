# Phase 4 — CloudWatch Monitoring & Alarms

## What this deploys

- 1 SNS topic with your email subscribed
- 3 Lambda alarms (errors, duration, throttles) on `search-api`
- 2 API Gateway alarms (5XX rate, p95 latency)
- 1 AWS Budget at $15/month with email alerts

## Files

| File | Drop into |
|------|-----------|
| `monitoring.tf` | `C:\Projects\library-finder-aws\terraform\` |
| `budget.tf` | `C:\Projects\library-finder-aws\terraform\` |
| `variables_phase4.tf` | Merge its content into your existing `variables.tf` |

## Setup steps (Windows PowerShell)

### 1. Verify resource references

Open `monitoring.tf` and check the `locals` block at the top. The references assume:

- Lambda resource: `aws_lambda_function.search_api`
- API Gateway REST API: `aws_api_gateway_rest_api.search_api`
- API Gateway stage: `aws_api_gateway_stage.dev`

If yours are named differently, update those three lines only.

### 2. Add the variable

Open your existing `variables.tf` and paste the `alarm_email` variable from `variables_phase4.tf`. Delete `variables_phase4.tf` after.

### 3. Set your email in terraform.tfvars

```hcl
alarm_email = "your-email@example.com"
```

### 4. Deploy

```powershell
cd C:\Projects\library-finder-aws\terraform
terraform plan
terraform apply
```

### 5. Confirm the SNS email subscription

Check your inbox for an "AWS Notification - Subscription Confirmation" email and click the confirm link. **Alarms will not fire until you confirm.**

## Verify it works

```powershell
# List your new alarms
aws cloudwatch describe-alarms --alarm-name-prefix "library-finder-dev" --region us-east-1 --query "MetricAlarms[].AlarmName"

# Trigger a test notification from the SNS topic
aws sns publish --topic-arn $(terraform output -raw sns_topic_arn) --message "Phase 4 test" --region us-east-1
```

You should receive the test email within ~30 seconds.

## Optional: force an alarm to fire (demo for interviews)

Temporarily set `threshold = -1` on `lambda_errors`, apply, wait 5 min, then revert. Shows the full alert loop working end-to-end — good talking point.

## Rollback

```powershell
terraform destroy -target=aws_cloudwatch_metric_alarm.lambda_errors -target=aws_cloudwatch_metric_alarm.lambda_duration -target=aws_cloudwatch_metric_alarm.lambda_throttles -target=aws_cloudwatch_metric_alarm.api_5xx_errors -target=aws_cloudwatch_metric_alarm.api_latency -target=aws_sns_topic.alarms -target=aws_budgets_budget.monthly
```

## Interview one-liner

> "I set up CloudWatch alarms on error rate, p95 latency, duration, and throttling for both Lambda and API Gateway, routed through SNS to email, plus an AWS Budget for cost guardrails. Five alarms total, all defined in Terraform and deployed via the CI/CD pipeline."
