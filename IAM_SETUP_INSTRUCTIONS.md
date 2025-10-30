# IAM Permissions Setup for cicd_bot User

## The Problem
The `cicd_bot` user doesn't have permissions to:
- `iot:DescribeEndpoint` - read IoT endpoint
- IoT resource creation/management
- CloudWatch dashboard creation
- S3 bucket creation

## Solution

### Option 1: Update IAM Policy via AWS Console (Quickest)

1. Go to AWS Console → IAM → Users
2. Find user: `cicd_bot`
3. Click "Add permissions" or "Permissions" tab
4. Create new policy or edit existing
5. Use the JSON from: `apis/infrastructure/iac/terraform/aws.config/iam.policy.json`

### Option 2: Apply via AWS CLI (If you have admin access)

```bash
# Get current account ID
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Replace YOUR_ACCOUNT_ID in the policy
sed "s/YOUR_ACCOUNT_ID/$ACCOUNT_ID/g" apis/infrastructure/iac/terraform/aws.config/iam.policy.json > /tmp/policy.json

# Attach policy to cicd_bot user
aws iam put-user-policy \
  --user-name cicd_bot \
  --policy-name TerraformInfrastructurePolicy \
  --policy-document file:///tmp/policy.json
```

### Option 3: Attach AWS Managed Policies (Simplest)

Attach these managed policies to `cicd_bot` user:

1. **PowerUserAccess** (or create custom):
   - This gives broad access but not IAM management
   
2. **Or specifically attach:**
   - `AmazonS3FullAccess` (for state bucket)
   - `AWSIoTDataAccess` (for IoT Core)
   - `AWSIoTConfigAccess` (for IoT management)
   - `CloudWatchFullAccess` (for dashboards)
   - `AmazonVPCFullAccess` (for networking)

### Option 4: Use GitHub Secrets with Different Credentials

If you can't modify the cicd_bot user, create a new IAM user:

1. Create new IAM user: `github-actions-terraform`
2. Attach the permissions from the policy file
3. Update GitHub Secrets:
   - `AWS_ACCESS_KEY_ID` (new user's key)
   - `AWS_SECRET_ACCESS_KEY` (new user's secret)

## Quick Fix for Testing

For quick testing, you can temporarily attach `PowerUserAccess` to `cicd_bot`:

```bash
aws iam attach-user-policy \
  --user-name cicd_bot \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

⚠️ **Warning**: PowerUserAccess is very broad. For production, use the custom policy.

## Verify Permissions

Test if it works:

```bash
aws --profile cicd_bot iot describe-endpoint --endpoint-type iot:Data-ATS
```

If this succeeds, permissions are correct!

## What the Updated Policy Includes

The updated `iam.policy.json` now has:

✅ **IoT Full Access** - All IoT operations (`iot:*`)  
✅ **CloudWatch Dashboard** - Create/manage dashboards  
✅ **S3 for State Bucket** - Create and manage state bucket  
✅ **VPC Full** - Networking resources  
✅ **EC2** - Security groups, subnets, etc.  
✅ **IAM** - Role creation for EKS/Kafka  

## Next Steps

After updating IAM permissions:

1. **Test locally in WSL:**
   ```bash
   cd apis/infrastructure/iac/terraform/services/mqtt
   terraform init
   terraform plan
   ```

2. **Or deploy via GitHub Actions:**
   - Go to Actions tab
   - Run "Deploy MQTT Service" workflow

The permissions error should be resolved!




