# GitHub Actions for Infrastructure Deployment

## Setup

### 1. Configure GitHub Secrets

Go to **Settings → Secrets and variables → Actions** and add:

- `AWS_ACCESS_KEY_ID` - Your AWS access key
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret key

### 2. Deploy MQTT Service

#### Option A: Manual Deploy (Recommended)
1. Go to **Actions** tab in GitHub
2. Select **"Deploy MQTT Service"** workflow
3. Click **"Run workflow"**
4. Select environment (dev/staging/prod)
5. Click **"Run workflow"**

#### Option B: Full Infrastructure Control
1. Go to **Actions** tab
2. Select **"Terraform Infrastructure"** workflow
3. Click **"Run workflow"**
4. Configure:
   - Action: `plan` or `apply`
   - Service: `all`, `bootstrap`, `networking`, or `mqtt`
   - Environment: `dev`, `staging`, or `prod`

### 3. On Pull Requests

When you create a PR that modifies Terraform files, the **Terraform Plan** workflow automatically:
- Runs `terraform plan` for both networking and MQTT
- Comments the results on the PR

## Workflows Overview

### 🔧 Infrastructure Terraform
**File:** `.github/workflows/infrastructure-terraform.yml`
- Full control over all infrastructure
- Bootstrap S3 bucket creation
- Deploy/destroy services independently
- Works with: bootstrap, networking, mqtt

### 🚀 MQTT Deploy
**File:** `.github/workflows/mqtt-deploy.yml`
- One-click MQTT service deployment
- Deploys networking first, then MQTT
- Shows outputs after deployment

### 📋 Terraform Plan
**File:** `.github/workflows/terraform-plan.yml`
- Automatic plan on PRs
- Comments plan results on PR

## What Gets Deployed?

### Bootstrap (run first time only)
- S3 bucket: `awsmqttpoc-terraform-state`
- State versioning enabled
- Server-side encryption

### Shared Networking
- VPC with public/private subnets
- Security groups for MQTT, Kafka, Spring Boot
- Internet Gateway

### MQTT Service
- AWS IoT Thing (device)
- IoT Certificate (cert for authentication)
- IoT Policy (permissions)
- CloudWatch Dashboard
- ~$0.50/month cost

## Cost Management

- **MQTT only**: ~$0.50/month
- **MQTT + shared networking**: ~$0.50/month (networking is mostly free)
- **Full infrastructure**: ~$88.50/month

Use **"Destroy All"** action in GitHub Actions to save costs when not needed.

## Secrets Required

```yaml
AWS_ACCESS_KEY_ID: <your-access-key>
AWS_SECRET_ACCESS_KEY: <your-secret-key>
```

Make sure your AWS IAM user/role has:
- S3 permissions (for state bucket)
- IoT permissions (for AWS IoT Core)
- VPC permissions (for networking)
- CloudWatch permissions (for dashboards)

## Next Steps

1. **Set up GitHub Secrets** (one time)
2. **Go to Actions tab**
3. **Run "Deploy MQTT Service"** workflow
4. **Get MQTT endpoint** from workflow outputs
5. **Start developing!** 🎉




