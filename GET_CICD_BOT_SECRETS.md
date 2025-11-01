# Getting Secrets for AWS cicd_bot User

## Overview

You mentioned using `cicd_bot` - this is likely your existing IAM user for CI/CD. Here's how to get all the values you need.

---

## Step 1: Get AWS Credentials for cicd_bot

### Option A: If cicd_bot User Already Exists

#### Get Access Key from AWS Console:

1. **AWS Console** → **IAM** → **Users**
2. Find user: `cicd_bot`
3. Click on the user
4. Go to **"Security credentials"** tab
5. Scroll to **"Access keys"** section
6. Two options:
   - **If key exists:** Click **"Show"** to reveal secret (or create new if needed)
   - **If no key exists:** Click **"Create access key"**

#### Or Get from AWS CLI (if already configured):

```bash
# Check if cicd_bot profile exists
aws configure list-profiles

# View cicd_bot credentials (if configured locally)
aws configure list --profile cicd_bot

# Get current access key (if using cicd_bot profile)
aws configure get aws_access_key_id --profile cicd_bot
aws configure get aws_secret_access_key --profile cicd_bot
```

⚠️ **Note:** CLI won't show the secret key - you'll need to get it from AWS Console or create a new one.

---

### Option B: Create New Access Key for cicd_bot

```bash
# Using AWS CLI (if you have admin access)
aws iam create-access-key --user-name cicd_bot --profile your-admin-profile

# Output will show:
# {
#   "AccessKey": {
#     "UserName": "cicd_bot",
#     "AccessKeyId": "AKIAIOSFODNN7EXAMPLE",
#     "Status": "Active",
#     "SecretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
#     "CreateDate": "2024-01-15T10:00:00Z"
#   }
# }
```

**Save both values:**
- `AccessKeyId` → GitHub Secret: `AWS_ACCESS_KEY_ID`
- `SecretAccessKey` → GitHub Secret: `AWS_SECRET_ACCESS_KEY`

---

## Step 2: Verify cicd_bot Permissions

Make sure `cicd_bot` has permissions to manage EC2:

```bash
# Test if cicd_bot can describe instances
aws ec2 describe-instances \
  --profile cicd_bot \
  --region us-east-1

# Test if it can start/stop instances (replace with your instance ID)
aws ec2 describe-instances \
  --instance-ids i-YOUR-INSTANCE-ID \
  --profile cicd_bot \
  --region us-east-1
```

**Required IAM Policy for cicd_bot:**

If `cicd_bot` doesn't have EC2 permissions, attach this policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EC2JenkinsManagement",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:StartInstances",
                "ec2:StopInstances",
                "ec2:DescribeInstanceAttribute"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "ec2:ResourceTag/ManagedBy": "jenkins"
                }
            }
        },
        {
            "Sid": "EC2DescribeAll",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus"
            ],
            "Resource": "*"
        }
    ]
}
```

**Or attach AWS managed policy:**
```bash
aws iam attach-user-policy \
  --user-name cicd_bot \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess \
  --profile your-admin-profile
```

⚠️ **Note:** `AmazonEC2FullAccess` is broad. For production, create a custom policy with only needed permissions.

---

## Step 3: Get EC2 Instance ID

### Find Your Jenkins EC2 Instance:

```bash
# List all EC2 instances with cicd_bot profile
aws ec2 describe-instances \
  --profile cicd_bot \
  --region us-east-1 \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' \
  --output table

# Output example:
# ------------------------------------------
# |         DescribeInstances              |
# +-------------+---------------+----------+
# |  i-abc123   |  Jenkins      | running  |
# |  i-def456   |  WebServer    | stopped  |
# +-------------+---------------+----------+
```

**Or in AWS Console:**
1. **EC2** → **Instances**
2. Find your Jenkins instance
3. Copy **Instance ID** (e.g., `i-0123456789abcdef0`)

**GitHub Secret:** `JENKINS_INSTANCE_ID` = `i-0123456789abcdef0`

---

## Step 4: Get Jenkins Credentials

### A. Jenkins Username

**Usually:**
- `admin` (default admin user)
- Or whatever username you created

**GitHub Secret:** `JENKINS_USER` = `admin` (or your username)

---

### B. Jenkins API Token

**Create Jenkins API Token:**

1. **Login to Jenkins** (http://your-jenkins-ip:8080)
2. Click your **username** (top right corner)
3. Click **"Configure"**
4. Scroll down to **"API Token"** section
5. Click **"Add new Token"**
6. Enter name: `github-actions-cicd-bot`
7. Click **"Generate"**
8. **Copy the token immediately!** (you won't see it again)

**GitHub Secret:** `JENKINS_TOKEN` = the token you copied

**Example token format:**
```
11abc123def456ghi789jkl012mno345pqr678stu901vwx234yz
```

---

### C. Jenkins Build Token

**Configure Build Token in Jenkins Job:**

1. **Jenkins** → Your Job (e.g., `aws-mqtt-poc-pipeline`)
2. Click **"Configure"**
3. Scroll to **"Build Triggers"** section
4. Enable: **"Trigger builds remotely (e.g., from scripts)"**
5. Enter **Authentication Token**: `github-actions-build-token`
6. Click **"Save"**

**GitHub Secret:** `JENKINS_BUILD_TOKEN` = `github-actions-build-token`

**Or use existing token if already configured.**

---

### D. Jenkins Job Name

**Find Your Pipeline Name:**

1. Go to **Jenkins Dashboard**
2. Look at the list of jobs/pipelines
3. Copy the **exact name** (case-sensitive)

**Examples:**
- `aws-mqtt-poc-pipeline`
- `main-build`
- `order-service-pipeline`

**GitHub Secret:** `JENKINS_JOB_NAME` = exact job name from dashboard

---

## Step 5: Complete Checklist

### Values to Collect:

| Secret | How to Get | Example |
|--------|------------|---------|
| `AWS_ACCESS_KEY_ID` | IAM → cicd_bot → Security credentials → Access keys | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | Same as above (shown when created) | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `JENKINS_INSTANCE_ID` | EC2 → Instances → Copy Instance ID | `i-0123456789abcdef0` |
| `JENKINS_USER` | Your Jenkins login username | `admin` |
| `JENKINS_TOKEN` | Jenkins → User → Configure → API Token → Generate | `11abc123...` |
| `JENKINS_BUILD_TOKEN` | Jenkins Job → Configure → Build Triggers → Token | `github-actions-build-token` |
| `JENKINS_JOB_NAME` | Jenkins Dashboard → Job name | `aws-mqtt-poc-pipeline` |

---

## Step 6: Test cicd_bot Can Access Jenkins Instance

```bash
# Get Jenkins instance public IP
JENKINS_IP=$(aws ec2 describe-instances \
  --instance-ids i-YOUR-INSTANCE-ID \
  --profile cicd_bot \
  --region us-east-1 \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "Jenkins IP: $JENKINS_IP"

# Test if Jenkins is accessible
curl -I http://$JENKINS_IP:8080
```

---

## Quick Setup Script

**If you have cicd_bot configured locally:**

```bash
#!/bin/bash
# Get all values for GitHub secrets

echo "=== AWS Credentials ==="
echo "AWS_ACCESS_KEY_ID:"
aws configure get aws_access_key_id --profile cicd_bot
echo ""
echo "AWS_SECRET_ACCESS_KEY: (get from AWS Console - IAM → cicd_bot → Security credentials)"
echo ""

echo "=== EC2 Instance ==="
echo "JENKINS_INSTANCE_ID:"
aws ec2 describe-instances \
  --profile cicd_bot \
  --region us-east-1 \
  --filters "Name=tag:Name,Values=Jenkins" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text
echo ""

echo "=== Jenkins Credentials ==="
echo "JENKINS_USER: (your Jenkins username)"
echo "JENKINS_TOKEN: (get from Jenkins UI → User → Configure → API Token)"
echo "JENKINS_BUILD_TOKEN: (configure in Jenkins Job → Build Triggers)"
echo "JENKINS_JOB_NAME: (check Jenkins Dashboard)"
```

---

## Verify cicd_bot Has Terraform Permissions (Optional)

Since you're using `cicd_bot` for Terraform, verify it has the right permissions:

```bash
# Check current policies attached to cicd_bot
aws iam list-attached-user-policies \
  --user-name cicd_bot \
  --profile your-admin-profile

aws iam list-user-policies \
  --user-name cicd_bot \
  --profile your-admin-profile
```

**If cicd_bot is used for Terraform, it likely already has EC2 permissions!**

---

## Common Issues

### Issue: "Access Denied" when starting instance
**Solution:** Verify cicd_bot has `ec2:StartInstances` permission

### Issue: "Cannot find instance"
**Solution:** 
- Check instance ID is correct
- Verify region matches (us-east-1)
- Check instance exists in that region

### Issue: "Jenkins authentication failed"
**Solution:**
- Verify username is correct (case-sensitive)
- Check API token is valid (create new one if needed)
- Test token manually: `curl -u USER:TOKEN http://JENKINS-IP:8080/api/json`

---

## Next Steps

Once you have all values:

1. ✅ Go to GitHub → Settings → Secrets → Actions
2. ✅ Add each secret (7 total)
3. ✅ Enable workflow: Change `if: false` to `if: true` in workflow file
4. ✅ Test by creating a PR

---

## Using Existing cicd_bot Profile

If `cicd_bot` is already configured in your AWS CLI:

```bash
# Check current config
cat ~/.aws/credentials | grep -A 5 cicd_bot

# Or
aws configure list --profile cicd_bot
```

**Use the same credentials** - they should already have the necessary permissions if you've been using them for Terraform!

