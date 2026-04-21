# =============================================================================
# GitHub Actions OIDC Authentication for AWS
# =============================================================================
# This file sets up secure, credential-less authentication for GitHub Actions
# to assume an IAM role in AWS. No long-lived access keys are stored anywhere.
#
# Flow:
#   GitHub runs workflow -> GitHub mints JWT token -> AWS STS validates token
#   -> AWS issues temporary credentials (15-60 min) -> Workflow uses them -> Expire
# =============================================================================


# -----------------------------------------------------------------------------
# Resource 1: OIDC Identity Provider
# -----------------------------------------------------------------------------
# Tells AWS to trust tokens signed by GitHub's OIDC service.
# This is a one-time, account-wide resource - only one per AWS account needed.
# -----------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  # GitHub's root CA thumbprints (SHA-1 fingerprints of TLS certificates)
  # AWS uses these to verify it's talking to real GitHub, not an impostor.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name        = "github-actions-oidc-provider"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}


# -----------------------------------------------------------------------------
# Variables for scoping the role to your specific repo
# -----------------------------------------------------------------------------

variable "github_org" {
  description = "GitHub organization or username that owns the repo"
  type        = string
  default     = "mittal-jn"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "library-finder-aws"
}


# -----------------------------------------------------------------------------
# Resource 2: IAM Role that GitHub Actions will assume
# -----------------------------------------------------------------------------
# The trust policy is the SECURITY HEART of this setup. It says:
# "This role can ONLY be assumed by GitHub Actions workflows running in the
#  specified repo, on specified branches, with a valid OIDC token."
# -----------------------------------------------------------------------------

resource "aws_iam_role" "github_actions" {
  name        = "${var.project_name}-github-actions-${var.environment}"
  description = "Role assumed by GitHub Actions workflows via OIDC"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          # Token's intended audience must be AWS STS
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          # Token's subject must match our repo and allowed refs
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main",
              "repo:${var.github_org}/${var.github_repo}:pull_request"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-github-actions-role"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}


# -----------------------------------------------------------------------------
# Resource 3: IAM Policy - what the role is ALLOWED to do
# -----------------------------------------------------------------------------
# Following principle of least privilege: grant ONLY what the pipeline needs.
# -----------------------------------------------------------------------------

resource "aws_iam_policy" "github_actions" {
  name        = "${var.project_name}-github-actions-policy-${var.environment}"
  description = "Permissions for GitHub Actions CI/CD pipeline"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LambdaDeployment"
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:PublishVersion",
          "lambda:InvokeFunction"
        ]
        Resource = "arn:aws:lambda:*:*:function:${var.project_name}-*"
      },
      {
        Sid    = "S3FrontendSync"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-frontend-*",
          "arn:aws:s3:::${var.project_name}-frontend-*/*"
        ]
      },
      {
        Sid    = "CloudWatchLogsRead"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      },
      {
        Sid    = "IdentityCheck"
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-github-actions-policy"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}


# -----------------------------------------------------------------------------
# Resource 4: Attach the policy to the role
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}


# -----------------------------------------------------------------------------
# Outputs: Role ARN (needed for GitHub Actions workflows)
# -----------------------------------------------------------------------------

output "github_actions_role_arn" {
  description = "ARN of the IAM role that GitHub Actions assumes via OIDC"
  value       = aws_iam_role.github_actions.arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC identity provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

