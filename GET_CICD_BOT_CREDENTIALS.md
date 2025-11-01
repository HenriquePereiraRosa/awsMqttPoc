# Getting cicd_bot Credentials for GitHub Secrets

Since you already have `cicd_bot` configured, here's how to get all the values:

---

## ✅ Step 1: Get AWS Credentials (cicd_bot)

You already have `cicd_bot` profile! Two ways to get credentials:

### Option A: From AWS Console (Recommended - Most Secure)

**The secret key is NOT stored in AWS CLI, so get it from AWS Console:**

1. **AWS Console** → **IAM** → **Users**
2. Find user: `cicd_bot` (or `cicd-bot` - check both)
3. Click on the user
4. **Security credentials** tab
5. Scroll to **"Access keys"**
6. **If key exists:**
   - Click **"Show"** to reveal secret (if it shows)
   - **OR** create new access key → **Copy both keys immediately!**
7. **If no key:** Click **"Create access key"** → **Copy both immediately**

**Values:**
- `AccessKeyId` → GitHub Secret: `AWS_ACCESS_KEY_ID`
- `SecretAccessKey` → GitHub Secret: `AWS_SECRET_ACCESS_KEY`

⚠️ **You won't see the secret key again after closing!**

---

### Option B: Get Access Key ID from CLI (Secret key still needed from Console)

```bash
# Get access key ID (this is visible in CLI)
aws configure get aws_access_key_id --profile cicd_bot

# Output example: AKIAIOSFODNN7EXAMPLE

# For secret key, you MUST get it from AWS Console (not stored in CLI)
```

---

## ✅ Step 2: Verify cicd_bot Can Access EC2

Since you're using `cicd_bot` for Terraform, it likely already has EC2 permissions. Test it:

```bash
# List EC2 instances (to find your Jenkins instance)
aws ec2 describe-instances \
  --profile cicd_bot \
  --region us-east-1 \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' \
  --output table

# This will show all instances. Look for your Jenkins instance.
```

**If you get "Access Denied":**
- `cicd_bot` needs EC2 permissions
- Check `IAM_SETUP_INSTRUCTIONS.md` for how to add permissions
- Or attach `AmazonEC2FullAccess` policy (temporarily for testing)

---

## ✅ Step 3: Get EC2 Instance ID

```bash
# Find Jenkins instance
aws ec2 describe-instances \
  --profile cicd_bot \
  --region us-east-1 \
  --filters "Name=tag:Name,Values=Jenkins" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text

# OR list all and find manually:
aws ec2 describe-instances \
  --profile cicd_bot \
  --region us-east-1 \
  --output table
```

**GitHub Secret:** `JENKINS_INSTANCE_ID` = Instance ID (e.g., `i-0123456789abcdef0`)

---

## ✅ Step 4: Get Jenkins Credentials

### A. Jenkins Username

**Common values:**
- `admin` (default)
- Or your custom username

**Test:** Try logging into Jenkins UI to confirm username.

**GitHub Secret:** `JENKINS_USER` = your Jenkins username

---

### B. Jenkins API Token

**Create in Jenkins UI:**

1. Login to Jenkins: `http://YOUR-JENKINS-IP:8080`
2. Click **username** (top right) → **Configure**
3. Scroll to **"API Token"** section
4. Click **"Add new Token"**
5. Name: `github-actions-cicd-bot`
6. Click **"Generate"**
7. **Copy token immediately!**

**Example token:** `11abc123def456ghi789jkl012mno345pqr678stu901vwx234yz`

**GitHub Secret:** `JENKINS_TOKEN` = the token you copied

---

### C. Jenkins Build Token

**Configure in Jenkins Job:**

1. Jenkins Dashboard → Your Job (e.g., `aws-mqtt-poc-pipeline`)
2. Click **"Configure"**
3. **Build Triggers** section
4. ✅ Enable: **"Trigger builds remotely (e.g., from scripts)"**
5. **Authentication Token:** Enter: `github-actions-build-token`
6. Click **"Save"**

**GitHub Secret:** `JENKINS_BUILD_TOKEN` = `github-actions-build-token`

---

### D. Jenkins Job Name

**Find in Jenkins Dashboard:**

1. Go to Jenkins: `http://YOUR-JENKINS-IP:8080`
2. Look at job/pipeline names
3. Copy **exact name** (case-sensitive!)

**Examples:**
- `aws-mqtt-poc-pipeline`
- `main-build`
- `your-project-pipeline`

**GitHub Secret:** `JENKINS_JOB_NAME` = exact job name

---

## Quick Command Summary

```bash
# 1. Get AWS Access Key ID (secret key from Console!)
aws configure get aws_access_key_id --profile cicd_bot

# 2. List EC2 instances to find Jenkins
aws ec2 describe-instances --profile cicd_bot --region us-east-1 --output table

# 3. Get Jenkins instance ID
aws ec2 describe-instances \
  --profile cicd_bot \
  --region us-east-1 \
  --filters "Name=tag:Name,Values=Jenkins" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text

# 4. Get Jenkins public IP (for accessing UI)
aws ec2 describe-instances \
  --profile cicd_bot \
  --region us-east-1 \
  --instance-ids i-YOUR-INSTANCE-ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text
```

---

## Complete Checklist

| Secret | Where to Get | Status |
|--------|--------------|--------|
| `AWS_ACCESS_KEY_ID` | AWS Console → IAM → cicd_bot → Access keys | ⬜ |
| `AWS_SECRET_ACCESS_KEY` | Same as above (shown when created) | ⬜ |
| `JENKINS_INSTANCE_ID` | EC2 Console or CLI command above | ⬜ |
| `JENKINS_USER` | Your Jenkins login username | ⬜ |
| `JENKINS_TOKEN` | Jenkins UI → User → Configure → API Token | ⬜ |
| `JENKINS_BUILD_TOKEN` | Jenkins Job → Configure → Build Triggers | ⬜ |
| `JENKINS_JOB_NAME` | Jenkins Dashboard → Job name | ⬜ |

---

## If cicd_bot Doesn't Have EC2 Permissions

**Add EC2 permissions to cicd_bot:**

```bash
# Option 1: Attach AWS managed policy (quick)
aws iam attach-user-policy \
  --user-name cicd_bot \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess \
  --profile default  # Use your admin profile

# Option 2: Create custom policy (recommended for production)
# Create policy from GET_CICD_BOT_SECRETS.md and attach it
```

---

## Test Everything Works

```bash
# Test AWS credentials
aws ec2 describe-instances \
  --profile cicd_bot \
  --region us-east-1

# Test Jenkins API (replace with your values)
JENKINS_IP="YOUR-JENKINS-IP"
JENKINS_USER="admin"
JENKINS_TOKEN="your-token"

curl -u "$JENKINS_USER:$JENKINS_TOKEN" \
  http://$JENKINS_IP:8080/api/json
```

---

## Next Steps

1. ✅ Get all 7 values above
2. ✅ Add to GitHub: Settings → Secrets → Actions → New repository secret
3. ✅ Enable workflow: Change `if: false` to `if: true` in workflow file
4. ✅ Test by creating a PR

**The secrets are automatically available in the workflow - no manual passing needed!** 🚀

