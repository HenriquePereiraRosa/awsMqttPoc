# How to Configure GitHub Secrets for Jenkins Workflow

## Step-by-Step Guide

### Step 1: Access Repository Settings

1. Go to your GitHub repository: `https://github.com/YOUR_USERNAME/YOUR_REPO`
2. Click on **Settings** (top menu)
3. In the left sidebar, click on **Secrets and variables** → **Actions**

---

### Step 2: Add Required Secrets

Click **"New repository secret"** for each secret below:

---

## Required Secrets

### 1. AWS Credentials

**Secret Name:** `AWS_ACCESS_KEY_ID`
- **Value:** Your AWS access key ID
- **How to get:**
  ```bash
  # In AWS Console:
  # 1. Go to IAM → Users → Your User
  # 2. Security credentials tab
  # 3. Create access key
  # OR use existing access key
  ```

**Secret Name:** `AWS_SECRET_ACCESS_KEY`
- **Value:** Your AWS secret access key (from step above)
- ⚠️ **Keep this secure!** Never commit to code

---

### 2. EC2 Instance Information

**Secret Name:** `JENKINS_INSTANCE_ID`
- **Value:** Your EC2 instance ID (e.g., `i-0123456789abcdef0`)
- **How to get:**
  ```bash
  # In AWS Console:
  # EC2 → Instances → Select your Jenkins instance
  # Copy the Instance ID (e.g., i-0123456789abcdef0)
  ```
- Or use AWS CLI:
  ```bash
  aws ec2 describe-instances --query 'Reservations[*].Instances[?Tags[?Key==`Name` && Value==`Jenkins`]].InstanceId' --output text
  ```

---

### 3. Jenkins Credentials

**Secret Name:** `JENKINS_USER`
- **Value:** Your Jenkins username (e.g., `admin` or `jenkins`)

**Secret Name:** `JENKINS_TOKEN`
- **Value:** Jenkins API token
- **How to create:**
  1. Login to Jenkins web UI
  2. Click your username (top right)
  3. Click **"Configure"**
  4. Under **"API Token"**, click **"Add new Token"**
  5. Give it a name (e.g., `github-actions`)
  6. Click **"Generate"**
  7. **Copy the token immediately** (you won't see it again!)
  8. Paste as the secret value

**Secret Name:** `JENKINS_BUILD_TOKEN`
- **Value:** Token for triggering builds (can be same as `JENKINS_TOKEN` or create separate)
- **How to configure in Jenkins:**
  1. Go to your Jenkins job
  2. Click **"Configure"**
  3. Under **"Build Triggers"**, enable **"Trigger builds remotely (e.g., from scripts)"**
  4. Enter a token (e.g., `github-actions-build`)
  5. Save
  6. Use this token value as the secret

**Secret Name:** `JENKINS_JOB_NAME`
- **Value:** Name of your Jenkins pipeline/job
- **Examples:**
  - `aws-mqtt-poc-pipeline`
  - `your-project-pipeline`
  - `main-build`
- **How to find:**
  - Look at your Jenkins dashboard
  - It's the name you see in the job list

---

## Quick Reference Table

| Secret Name | Example Value | Where to Get It |
|-------------|---------------|-----------------|
| `AWS_ACCESS_KEY_ID` | `AKIAIOSFODNN7EXAMPLE` | AWS IAM Console |
| `AWS_SECRET_ACCESS_KEY` | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` | AWS IAM Console |
| `JENKINS_INSTANCE_ID` | `i-0123456789abcdef0` | AWS EC2 Console |
| `JENKINS_USER` | `admin` | Your Jenkins login |
| `JENKINS_TOKEN` | `11abc123def456ghi789jkl` | Jenkins → User → Configure → API Token |
| `JENKINS_BUILD_TOKEN` | `github-actions-build` | Jenkins Job → Configure → Build Triggers |
| `JENKINS_JOB_NAME` | `aws-mqtt-poc-pipeline` | Your Jenkins dashboard |

---

## Security Best Practices

### 1. Use IAM User with Limited Permissions

**Create a dedicated IAM user for GitHub Actions:**

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:StartInstances",
                "ec2:StopInstances"
            ],
            "Resource": "arn:aws:ec2:us-east-1:ACCOUNT_ID:instance/INSTANCE_ID"
        }
    ]
}
```

**Attach this policy to a new IAM user:**
```bash
# AWS Console: IAM → Users → Create User
# Name: github-actions-jenkins
# Attach the policy above
# Create access key
# Use these credentials in GitHub secrets
```

---

### 2. Rotate Secrets Regularly

- **AWS Keys:** Rotate every 90 days
- **Jenkins Tokens:** Rotate every 180 days
- **Build Tokens:** Rotate when compromised

---

### 3. Use Repository-Level Secrets

✅ **Do:** Add secrets at repository level (Settings → Secrets)  
❌ **Don't:** Hardcode secrets in workflow files  
❌ **Don't:** Commit secrets to Git

---

## Testing Your Secrets

### Test AWS Credentials:

```bash
# Test if AWS credentials work
aws ec2 describe-instances \
  --instance-ids i-YOUR-INSTANCE-ID \
  --region us-east-1

# Should return your instance details without error
```

### Test Jenkins API:

```bash
# Replace with your values
JENKINS_URL="http://YOUR-JENKINS-IP:8080"
JENKINS_USER="admin"
JENKINS_TOKEN="your-token"

# Test connection
curl -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/api/json"

# Should return Jenkins info in JSON format
```

---

## Troubleshooting

### Error: "AWS credentials not found"
- ✅ Check secret names are exactly: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
- ✅ Verify secrets are added under "Actions" secrets (not "Dependabot")
- ✅ Check for typos in secret names

### Error: "Instance not found"
- ✅ Verify `JENKINS_INSTANCE_ID` is correct (e.g., `i-0123456789abcdef0`)
- ✅ Check AWS region matches your instance region
- ✅ Verify AWS credentials have permission to describe instances

### Error: "Jenkins authentication failed"
- ✅ Verify `JENKINS_USER` and `JENKINS_TOKEN` are correct
- ✅ Check Jenkins token hasn't expired
- ✅ Test token manually with curl command above

### Error: "Job not found"
- ✅ Verify `JENKINS_JOB_NAME` matches exactly (case-sensitive)
- ✅ Check job exists in Jenkins
- ✅ Verify `JENKINS_BUILD_TOKEN` is configured in job settings

---

## Alternative: Using GitHub Environment Secrets

For better organization, you can use **Environments**:

1. Go to **Settings** → **Environments**
2. Click **"New environment"**
3. Name it: `jenkins-production`
4. Add all secrets there
5. Reference in workflow:

```yaml
jobs:
  start-jenkins:
    environment: jenkins-production
    # Secrets are automatically available
```

---

## Complete Example Workflow with Secrets

After adding all secrets, your workflow will automatically use them:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v2
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}  # ✅ Auto-loaded
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}  # ✅ Auto-loaded
    aws-region: us-east-1

- name: Trigger Jenkins build
  run: |
    JENKINS_URL="${{ steps.jenkins-url.outputs.url }}"
    JOB_NAME="${{ secrets.JENKINS_JOB_NAME }}"  # ✅ Auto-loaded
    # ... rest of workflow
```

**No need to manually pass secrets - GitHub handles it automatically!** ✅

---

## Quick Setup Checklist

- [ ] AWS access key created in IAM
- [ ] AWS secret access key copied
- [ ] EC2 instance ID copied
- [ ] Jenkins username noted
- [ ] Jenkins API token generated
- [ ] Jenkins build token configured
- [ ] Jenkins job name confirmed
- [ ] All secrets added to GitHub repository
- [ ] Secrets tested (use test commands above)
- [ ] Workflow enabled (`if: false` → `if: true`)

---

## Need Help?

If you get stuck:
1. Check GitHub Actions logs for specific error messages
2. Test each secret individually using the test commands
3. Verify secret names match exactly (case-sensitive)
4. Check AWS permissions for the IAM user

