# LibraryFinder AWS — Claude Handoff

**Last updated:** 2026-04-21
**Current phase:** Phase 4 complete ✅

---

## Project overview

Full-stack serverless library search application built as a portfolio project to demonstrate AWS infrastructure competence.

**Stack:** Terraform (IaC), AWS Lambda, RDS PostgreSQL, S3, API Gateway v2 (HTTP API), CloudWatch, SNS, AWS Budgets

**AWS account:** configured via local AWS CLI profile | **Region:** `us-east-1`

**Working directory:** `<LOCAL_PROJECT_PATH>\terraform\phase1-serverless\` (Windows PowerShell)

**RDS instance:** `library-finder-db-dev` — PostgreSQL with 10 sample library records, kept stopped when not actively coding to reduce cost.

> **Note:** All AWS account-specific values (account ID, IAM user name, email) live only in local `terraform.tfvars` (gitignored) and GitHub Actions secrets. Never committed.

---

## Phase status

| Phase | Status | Summary |
|---|---|---|
| 2A — Core infrastructure | ✅ Complete | VPC, subnets, security groups, RDS, S3, IAM |
| 2B — Search API Lambda | ✅ Complete | Lambda + API Gateway v2 (HTTP API), CORS working |
| 3 — CI/CD pipeline | ✅ Complete | GitHub Actions + OIDC federation, no stored secrets |
| 4 — Monitoring & alarms | ✅ Complete | 5 CloudWatch alarms, SNS email, AWS Budget |
| 5 — TBD | 🔜 Not started | See options below |

---

## Phase 4 — what was built (2026-04-21)

**Files added/modified:**
- `terraform/phase1-serverless/monitoring.tf` — SNS topic + 5 CloudWatch alarms
- `terraform/phase1-serverless/budget.tf` — AWS Budget resource
- `terraform/phase1-serverless/variables.tf` — added `alarm_email` variable
- `terraform/phase1-serverless/terraform.tfvars` — populated `alarm_email` (gitignored)

**Resources deployed (8 total):**

1. `aws_sns_topic.alarms` → `library-finder-dev-alarms`
2. `aws_sns_topic_subscription.alarms_email` → email protocol, confirmed
3. `aws_cloudwatch_metric_alarm.lambda_errors` → `library-finder-dev-lambda-errors`
4. `aws_cloudwatch_metric_alarm.lambda_duration` → `library-finder-dev-lambda-duration-high`
5. `aws_cloudwatch_metric_alarm.lambda_throttles` → `library-finder-dev-lambda-throttles`
6. `aws_cloudwatch_metric_alarm.api_5xx_errors` → `library-finder-dev-api-5xx-rate`
7. `aws_cloudwatch_metric_alarm.api_latency` → `library-finder-dev-api-latency-p95`
8. `aws_budgets_budget.monthly` → `library-finder-monthly-budget` at $15/mo

**Alarm thresholds:**

| Alarm | Threshold | Window |
|---|---|---|
| Lambda errors | > 0 | 5 min |
| Lambda duration | > 80% of timeout | 10 min (2× 5-min periods) |
| Lambda throttles | > 0 | 5 min |
| API Gateway 5xx rate | > 1% | 10 min |
| API Gateway p95 latency | > 2000 ms | 10 min |

**Budget thresholds:**
- 80% of $15 actual → email alert
- 100% of $15 forecasted → email alert

**Verification performed:**
- ✅ SNS subscription confirmed via inbox link
- ✅ All 5 alarms transitioned INSUFFICIENT_DATA → OK and delivered confirmation emails
- ✅ Manual SNS publish test (`aws sns publish`) delivered successfully
- ✅ End-to-end alert pipeline confirmed working

---

## Key learnings from Phase 4

- **API Gateway v1 vs v2 metric differences:** HTTP API (v2) uses `ApiId` + `Stage` dimensions and `5xx`/`4xx` metric names. REST API (v1) uses `ApiName` + `Stage` and `5XXError`/`4XXError`. Getting this wrong causes alarms to silently never fire because the metric lookup returns no data.
- **Duplicate variable declarations** surface immediately on `terraform plan` — check existing `variables.tf` before merging new variable files.
- **Alarms auto-fire on first evaluation** as they transition from `INSUFFICIENT_DATA` to `OK`. This is a free built-in test of the notification path.
- **`ok_actions` doubles email volume** — useful for verification, can be removed later to reduce noise.

---

## Carried-over learnings (Phases 2A/2B/3)

- Lambda Function URLs introduce CORS complications; API Gateway is more reliable for frontend-facing endpoints in this stack.
- `terraform apply -replace="aws_lambda_function.search_api"` forces Lambda redeployment when Terraform detects no changes.
- PowerShell has JSON encoding quirks that interfere with direct Lambda invocation via CLI.
- OIDC federation for GitHub Actions eliminates long-lived AWS access keys in CI/CD.

---

## Resource name reference (for future Terraform edits)

```hcl
# Lambda
aws_lambda_function.search_api
aws_lambda_function.db_setup

# API Gateway v2 (HTTP API)
aws_apigatewayv2_api.search_api
aws_apigatewayv2_stage.api
aws_apigatewayv2_integration.search_api
aws_apigatewayv2_route.root

# Lambda log group
aws_cloudwatch_log_group.lambda_search_api
```

---

## Cost controls in place

- RDS stopped when not actively coding (dominant cost)
- AWS Budget at $15/month with alerts at 80% actual + 100% forecasted
- Lambda + API Gateway v2 usage is effectively free at current volume

---

## Phase 5 — options to choose from

**Option A — CloudWatch Dashboard (2–3 hours, low complexity)**
Single consolidated dashboard with Lambda + API Gateway metrics. Visual artifact for README screenshots and interview demos.

**Option B — X-Ray distributed tracing (3–4 hours, medium complexity)**
Enable X-Ray on Lambda + API Gateway. Demonstrates observability beyond metrics.

**Option C — Aurora Serverless v2 migration (5–7 hours, higher complexity)**
Replace RDS PostgreSQL with Aurora Serverless v2. Scales to zero.

**Option D — Stop here and polish**
Polish the README, record a demo, practice interviews, ship what you have.

**Recommended:** Option D now for job-search urgency.

---

## How to resume in a new chat

> "Continuing LibraryFinder AWS project. Phase 4 (CloudWatch monitoring + SNS + AWS Budget) is complete and verified end-to-end. Starting [Phase 5 option] — see CLAUDE_HANDOFF.md for full context."

---

## Interview one-liner for Phase 4

> "I deployed CloudWatch alarms for error rate, p95 latency, duration, and throttling across Lambda and API Gateway v2, routed through SNS to email, plus an AWS Budget for cost control. All defined in Terraform and verified end-to-end — I tested the alert pipeline with a direct SNS publish to prove the notification path works independently of the alarm logic."
