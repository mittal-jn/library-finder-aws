# LibraryFinder

> Production-ready AWS library discovery platform with automated infrastructure, comprehensive monitoring, and CI/CD pipelines.

[![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazon-aws)](https://aws.amazon.com)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform)](https://www.terraform.io)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 🎯 Overview

LibraryFinder is a cloud-native application that helps users discover public libraries across the United States. Built with AWS best practices, the platform demonstrates production-ready infrastructure patterns including:

- **Multi-tier architecture** with separated frontend, API, and data layers
- **Infrastructure as Code** using Terraform modules
- **Automated deployments** via CI/CD pipelines
- **Comprehensive monitoring** with CloudWatch dashboards
- **Cost-optimized** design staying within AWS Free Tier where possible

## 🏗️ Architecture

```
Users → CloudFront (CDN) → S3 (Frontend)
                         ↓
                    API Gateway / ALB
                         ↓
                    Lambda / EC2 (API)
                         ↓
                    RDS PostgreSQL
```



## 🚀 Technologies

### Cloud Infrastructure
- **AWS Services**: EC2, S3, RDS, Lambda, CloudFront, ALB, VPC, CloudWatch, IAM
- **Infrastructure as Code**: Terraform (modular design)
- **Containerization**: Docker

### Development
- **Backend**: Node.js / Python
- **Frontend**: HTML5, CSS3, JavaScript (Vanilla)
- **Database**: PostgreSQL
- **API**: RESTful design

### DevOps
- **CI/CD**: GitHub Actions
- **Security Scanning**: TFSec, Checkov, Trivy
- **Cost Management**: Infracost, AWS Cost Explorer
- **Monitoring**: CloudWatch, custom metrics

## 📂 Project Structure

```
library-finder-aws/
├── frontend/              # Static website (S3 + CloudFront)
├── backend/
│   ├── lambda/           # Serverless functions (Phase 1)
│   ├── docker/           # Containerized API (Phase 2)
│   └── api/              # Application code
├── terraform/
│   ├── modules/          # Reusable Terraform modules
│   ├── phase1-serverless/    # Lambda + RDS implementation
│   ├── phase2-containers/    # EC2 + Docker migration
│   └── environments/         # Dev/Prod configurations
├── docs/                 # Architecture docs & recordings
├── scripts/              # Deployment & utility scripts
└── .github/workflows/    # CI/CD pipelines
```

## 🎬 Demo

**Live Demo**: [Coming Soon]

**Video Walkthrough**: [docs/recordings/](docs/recordings/)

## 🛠️ Quick Start

### Prerequisites
- AWS Account with IAM credentials configured
- Terraform >= 1.6.0
- AWS CLI >= 2.0
- Node.js >= 18.0 (for local development)

### Setup

```bash
# Clone repository
git clone https://github.com/mittal-jn/library-finder-aws.git
cd library-finder-aws

# Configure AWS credentials
aws configure

# Initialize Terraform
cd terraform/phase1-serverless
terraform init

# Review infrastructure plan
terraform plan

# Deploy infrastructure
terraform apply
```

### Local Development

```bash
# Frontend
cd frontend
# Open index.html in browser

# Backend (Lambda - local testing)
cd backend/lambda/search-api
npm install
npm test
```

## 📊 Key Features

- ✅ **Location-based search** - Find libraries by city, state, or ZIP code
- ✅ **Real-time results** - Fast searches using optimized database queries
- ✅ **Comprehensive data** - Library name, address, website, and hours
- ✅ **High availability** - Multi-AZ deployment with automatic failover
- ✅ **Cost optimized** - ~$30-35/month using t3.micro instances
- ✅ **Security hardened** - IAM roles, security groups, encryption at rest
- ✅ **Monitored** - CloudWatch dashboards tracking 5+ AWS services
- ✅ **Automated** - CI/CD pipeline with security scanning

## 🔒 Security

- **IAM roles** instead of access keys
- **Encryption** at rest (RDS, S3)
- **Security groups** with least-privilege access
- **Automated scanning** with TFSec and Checkov
- **Secret management** via AWS Secrets Manager
- **HTTPS** enforced via CloudFront

## 💰 Cost Analysis

**Estimated monthly cost:** ~$30-35

| Service | Cost/Month | Optimization |
|---------|-----------|--------------|
| EC2 (t3.micro) | ~$8 | Stop when not needed |
| RDS (t3.micro) | ~$15 | Single-AZ for dev |
| ALB | ~$16 | Required for HA |
| S3 + CloudFront | <$1 | Free tier covers most |
| Lambda + CloudWatch | $0 | Within free tier |

**Cost saving strategies implemented:**
- t3.micro instances (smallest production-viable size)
- No NAT Gateway (save $30/month)
- Single-AZ RDS for dev/demo
- S3 lifecycle policies
- CloudWatch log retention limits

## 📈 Monitoring & Observability

**CloudWatch Dashboards:**
- EC2 CPU, memory, network metrics
- RDS connections, query performance
- Lambda invocation count, duration, errors
- ALB request count, target health, response times
- Custom application metrics

**Alarms configured for:**
- High CPU utilization (>80%)
- Database connection limits
- API error rates (>5%)
- Unhealthy targets

## 🚀 Deployment Phases

### Phase 1: Serverless Foundation (Current)
- S3 static website
- Lambda API functions
- RDS PostgreSQL database
- Basic monitoring

### Phase 2: Container Migration (Planned)
- Migrate to EC2 + Docker
- Application Load Balancer
- Auto Scaling Groups
- Enhanced monitoring

### Phase 3: CI/CD Automation (Planned)
- GitHub Actions workflows
- Automated testing
- Security scanning
- Blue/green deployments

## 📚 Documentation

- [Architecture Overview](docs/architecture/)
- [Deployment Guide](docs/runbooks/deployment.md)
- [Disaster Recovery](docs/runbooks/disaster-recovery.md)
- [Troubleshooting](docs/runbooks/troubleshooting.md)
- [API Documentation](docs/api/)

## 🤝 Contributing

This is a portfolio project, but suggestions are welcome! Please open an issue to discuss proposed changes.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Mittal Jain**
- GitHub: [@mittal-jn](https://github.com/mittal-jn)
- LinkedIn: https://www.linkedin.com/in/mittaljain/
- Portfolio: https://github.com/mittal-jn

## 🙏 Acknowledgments

- AWS Documentation and Best Practices
- Terraform Registry for module patterns
- HashiCorp Learn tutorials
- AWS Solutions Architecture guides

---

**⭐ Star this repo if you find it helpful!**

**📧 Questions?** Open an issue or reach out via LinkedIn.
