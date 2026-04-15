# LibraryFinder Phase 1 - Security Groups (Fixed)
# Firewall rules following least-privilege principle
# Fixed: Removed circular dependency by using separate rules

# ==========================================
# Lambda Security Group
# ==========================================

resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-lambda-sg-${var.environment}"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-lambda-sg-${var.environment}"
  }
}

# Lambda egress rules (separate resources to avoid circular dependency)
resource "aws_security_group_rule" "lambda_to_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda.id
  source_security_group_id = aws_security_group.rds.id
  description              = "PostgreSQL to RDS"
}

resource "aws_security_group_rule" "lambda_to_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTPS outbound"
}

resource "aws_security_group_rule" "lambda_to_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP outbound"
}

# ==========================================
# RDS Security Group
# ==========================================

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg-${var.environment}"
  description = "Security group for RDS PostgreSQL database"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-rds-sg-${var.environment}"
  }
}

# RDS ingress rule (separate resource to avoid circular dependency)
resource "aws_security_group_rule" "rds_from_lambda" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.lambda.id
  description              = "PostgreSQL from Lambda"
}

# RDS egress rule
resource "aws_security_group_rule" "rds_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.rds.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "All outbound"
}

# ==========================================
# VPC Endpoint Security Group (for future use)
# ==========================================

resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project_name}-vpc-endpoints-sg-${var.environment}"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-vpc-endpoints-sg-${var.environment}"
  }
}

# VPC Endpoints ingress rule
resource "aws_security_group_rule" "vpc_endpoints_from_lambda" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpc_endpoints.id
  source_security_group_id = aws_security_group.lambda.id
  description              = "HTTPS from Lambda"
}

# VPC Endpoints egress rule
resource "aws_security_group_rule" "vpc_endpoints_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.vpc_endpoints.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "All outbound"
}
