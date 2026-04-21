# =============================================================================
# Phase 4: AWS Budget (Cost Guardrail)
# =============================================================================
# $15/month budget with email alerts at 80% actual and 100% forecasted.
# =============================================================================

resource "aws_budgets_budget" "monthly" {
  name         = "library-finder-monthly-budget"
  budget_type  = "COST"
  limit_amount = "15"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Alert at 80% of actual spend
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type           = "ACTUAL"
    subscriber_email_addresses = [var.alarm_email]
  }

  # Alert at 100% forecasted spend
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type           = "FORECASTED"
    subscriber_email_addresses = [var.alarm_email]
  }
}
