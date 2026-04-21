# LibraryFinder Phase 1 - Serverless Infrastructure
# Provider and Backend Configuration

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Uncomment after creating S3 bucket for state (Day 2)
  # backend "s3" {
  #   bucket         = "library-finder-terraform-state"
  #   key            = "phase1/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  # }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region

  # Default tags applied to all resources
  default_tags {
    tags = {
      Project     = "LibraryFinder"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Phase       = "Phase1-Serverless"
      Owner       = "mittal-jn"
    }
  }
}

# Random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# Data source: Get current AWS account ID
data "aws_caller_identity" "current" {}

# Data source: Get available AZs in current region
data "aws_availability_zones" "available" {
  state = "available"
}
