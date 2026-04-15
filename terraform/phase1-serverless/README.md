# LibraryFinder Phase 1 - Serverless Infrastructure

Production-ready AWS infrastructure using Terraform.

## 🏗️ Architecture

```
VPC (10.0.0.0/16)
├── Public Subnets (2 AZs)
│   └── Internet Gateway
├── Private Subnets (2 AZs)
│   ├── Lambda Functions
│   └── RDS PostgreSQL
├── S3 Bucket
│   └── Static Website Hosting
└── CloudWatch
    └── Monitoring & Logs
```

## 📋 Prerequisites

- [x] AWS CLI configured (`aws configure`)
- [x] Terraform >= 1.6.0 installed
- [x] AWS account with billing alerts set

## 🚀 Quick Start

### Step 1: Configure Variables

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values (IMPORTANT: Set db_password!)
code terraform.tfvars  # or notepad terraform.tfvars
```

**Minimum required in terraform.tfvars:**
```hcl
db_password = "YourSecurePassword123!"
alarm_email = "your-email@example.com"
```

### Step 2: Initialize Terraform

```bash
# Initialize Terraform (downloads providers)
terraform init
```

Expected output:
```
Terraform has been successfully initialized!
```

### Step 3: Plan Deployment

```bash
# See what will be created
terraform plan
```

This shows you:
- VPC and networking resources
- S3 bucket for frontend
- RDS PostgreSQL database
- Security groups
- Estimated costs

### Step 4: Deploy Infrastructure

```bash
# Deploy everything
terraform apply

# Type 'yes' when prompted
```

Deployment takes **~10-15 minutes** (mostly RDS provisioning).

### Step 5: View Outputs

```bash
# See deployed resource information
terraform output
```

Important outputs:
- `s3_website_url` - Your frontend URL
- `rds_endpoint` - Database connection endpoint
- `next_steps` - What to do after deployment

## 📊 What Gets Created

| Resource | Purpose | Monthly Cost |
|----------|---------|--------------|
| VPC | Network isolation | $0 |
| Subnets (4) | Network segmentation | $0 |
| Internet Gateway | Public internet access | $0 |
| S3 Bucket | Frontend hosting | <$1 |
| RDS PostgreSQL (t3.micro) | Database | ~$15 |
| Security Groups | Firewall rules | $0 |
| VPC Endpoints | Private AWS service access | $0 |
| CloudWatch Logs | Monitoring | $0 (free tier) |
| **Total** | | **~$15-16/month** |

## 🔒 Security Features

✅ **Network Security**
- Private subnets for database
- Security groups with least-privilege rules
- No public database access

✅ **Data Security**
- RDS encryption at rest
- S3 encryption at rest
- IAM roles (no hardcoded credentials)

✅ **Monitoring**
- CloudWatch Logs enabled
- Performance Insights enabled
- Connection logging

## 🧪 Testing After Deployment

### Test S3 Website

```bash
# Get website URL
terraform output s3_website_url

# Visit in browser or:
curl $(terraform output -raw s3_website_url)
```

### Test Database Connection

```bash
# Get database endpoint
terraform output rds_endpoint

# Connect using psql
psql -h <RDS_ADDRESS> -U admin -d libraryfinder
# Enter password when prompted
```

### Upload Frontend to S3

```bash
# From project root
cd ../../..
aws s3 sync frontend s3://$(cd terraform/phase1-serverless && terraform output -raw s3_bucket_name)/
```

## 🛠️ Common Commands

```bash
# View current state
terraform show

# List all resources
terraform state list

# Get specific output
terraform output s3_bucket_name

# Refresh outputs (if something changed)
terraform refresh

# Destroy everything (careful!)
terraform destroy
```

## 💰 Cost Optimization

### Current Configuration (~$16/month)

```hcl
enable_nat_gateway = false       # Saves $30/month
enable_multi_az_rds = false      # Saves $15/month
db_instance_class = "db.t3.micro"  # Smallest production instance
```

### If You Need to Cut Costs Further

**Stop RDS when not using:**
```bash
aws rds stop-db-instance --db-instance-identifier library-finder-db-dev
```

**Restart when needed:**
```bash
aws rds start-db-instance --db-instance-identifier library-finder-db-dev
```

**Note:** RDS auto-starts after 7 days of being stopped.

## 🐛 Troubleshooting

### Error: "InvalidParameterValue: DB Password must be at least 8 characters"

**Solution:** Set a longer password in `terraform.tfvars`

### Error: "Error creating DB Instance: DBInstanceAlreadyExists"

**Solution:** Database with that name exists. Either:
1. Destroy it: `terraform destroy`
2. Import it: `terraform import aws_db_instance.main library-finder-db-dev`

### Error: "Error creating S3 bucket: BucketAlreadyExists"

**Solution:** S3 bucket names are globally unique. The random suffix should prevent this, but if it happens:
1. Run `terraform destroy`
2. Run `terraform apply` again (new random suffix)

### Plan shows changes but nothing changed?

**Solution:** Run `terraform refresh` to sync state with AWS.

## 📚 File Structure

```
phase1-serverless/
├── provider.tf              # AWS provider configuration
├── variables.tf             # Input variables
├── vpc.tf                   # VPC and networking
├── security-groups.tf       # Firewall rules
├── s3.tf                    # Frontend bucket
├── rds.tf                   # PostgreSQL database
├── outputs.tf               # Output values
├── terraform.tfvars.example # Example configuration
└── README.md                # This file
```

## 🎯 Next Steps

After successful deployment:

1. ✅ **Upload Frontend to S3**
   ```bash
   cd ../../..
   aws s3 sync frontend s3://$(cd terraform/phase1-serverless && terraform output -raw s3_bucket_name)/
   ```

2. ✅ **Test Website**
   - Visit the S3 website URL from outputs
   - Search won't work yet (needs Lambda API)

3. ✅ **Create Database Tables**
   - Connect to RDS
   - Run schema creation SQL

4. ✅ **Create Lambda Function**
   - We'll do this in the next phase

5. ✅ **Set Up Monitoring**
   - Create CloudWatch dashboard
   - Configure alarms

## 🔄 Updating Infrastructure

```bash
# After changing .tf files:
terraform plan   # Review changes
terraform apply  # Apply changes
```

## 🗑️ Destroying Infrastructure

```bash
# Delete everything (careful!)
terraform destroy

# Type 'yes' when prompted
```

**Note:** This is reversible - you can always `terraform apply` again.

## 📖 Additional Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [AWS S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)

---

**Ready to deploy?** Run `terraform apply` and watch your infrastructure come to life! 🚀
