# Jenkins on AWS EC2: Auto-Start/Stop Setup (Cost Optimization)

## Concept: On-Demand Jenkins

**Instead of running 24/7 ($40/month), run only when needed:**
- ✅ **Start**: When PR is created/updated (via webhook)
- ✅ **Run**: Execute builds
- ✅ **Stop**: Automatically sleep after X minutes of inactivity
- 💰 **Cost**: ~$5-10/month (only paying when running)

---

## Architecture

```
PR Created/Updated (GitHub)
    ↓
GitHub Webhook
    ↓
AWS Lambda Function
    ↓
Start EC2 Instance
    ↓
Jenkins Builds
    ↓
Idle Detection (15 min)
    ↓
Stop EC2 Instance
```

---

## Setup Guide

### Step 1: Create EC2 Instance (with Auto-Stop Script)

#### Launch EC2 Instance:
```bash
# Instance specs
- Type: t3.medium (2 vCPU, 4GB RAM)
- OS: Ubuntu 22.04 LTS
- Storage: 30GB gp3
- Security Group: Allow HTTP (8080), SSH (22)
```

#### Install Jenkins:
```bash
# On EC2 instance
sudo apt update
sudo apt install openjdk-21-jdk -y

# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins -y

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

#### Install Auto-Stop Script:
```bash
# Create auto-stop script
sudo nano /opt/jenkins-auto-stop.sh
```

**Script content:**
```bash
#!/bin/bash
# Auto-stop Jenkins EC2 instance after idle period

IDLE_TIMEOUT=900  # 15 minutes in seconds
CHECK_INTERVAL=60  # Check every minute

LAST_ACTIVITY=$(date +%s)
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
REGION=$(ec2-metadata --availability-zone | cut -d " " -f 2 | sed 's/[a-z]$//')

while true; do
    sleep $CHECK_INTERVAL
    
    # Check if Jenkins has active builds
    ACTIVE_BUILDS=$(curl -s http://localhost:8080/computer/api/json | jq -r '.computer[0].executors[] | select(.currentExecutable != null) | .currentExecutable.url' | wc -l)
    
    # Check if Jenkins has queued builds
    QUEUED_BUILDS=$(curl -s http://localhost:8080/queue/api/json | jq -r '.items | length')
    
    if [ "$ACTIVE_BUILDS" -gt 0 ] || [ "$QUEUED_BUILDS" -gt 0 ]; then
        # Has active/queued builds - reset timer
        LAST_ACTIVITY=$(date +%s)
        echo "$(date): Active builds detected, resetting timer"
    else
        # No active builds - check if timeout exceeded
        CURRENT_TIME=$(date +%s)
        IDLE_TIME=$((CURRENT_TIME - LAST_ACTIVITY))
        
        if [ $IDLE_TIME -ge $IDLE_TIMEOUT ]; then
            echo "$(date): No activity for $IDLE_TIME seconds, stopping instance"
            
            # Stop Jenkins gracefully
            sudo systemctl stop jenkins
            
            # Stop EC2 instance
            aws ec2 stop-instances --instance-ids $INSTANCE_ID --region $REGION
            
            # Exit script (instance will stop)
            exit 0
        else
            echo "$(date): Idle for $IDLE_TIME seconds (timeout: $IDLE_TIMEOUT)"
        fi
    fi
done
```

**Make executable and install dependencies:**
```bash
sudo chmod +x /opt/jenkins-auto-stop.sh

# Install required tools
sudo apt install awscli jq -y
sudo apt install ec2-instance-connect -y

# Configure AWS CLI (attach IAM role to EC2 for permissions)
# Or use: aws configure
```

**Create systemd service:**
```bash
sudo nano /etc/systemd/system/jenkins-auto-stop.service
```

**Service content:**
```ini
[Unit]
Description=Jenkins Auto-Stop Service
After=jenkins.service network.target

[Service]
Type=simple
ExecStart=/opt/jenkins-auto-stop.sh
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
```

**Enable service:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable jenkins-auto-stop.service
sudo systemctl start jenkins-auto-stop.service
```

---

### Step 2: Create IAM Role for EC2 Instance

**IAM Policy for EC2 (allows instance to stop itself):**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:StopInstances",
                "ec2:DescribeInstanceStatus"
            ],
            "Resource": "*"
        }
    ]
}
```

**Attach role to EC2 instance:**
- Go to EC2 Console → Instances → Select instance → Actions → Security → Modify IAM role
- Attach the role created above

---

### Step 3: Create Lambda Function (Auto-Start on PR)

#### Create Lambda Function:
- Runtime: Python 3.11
- Handler: `lambda_function.lambda_handler`
- Role: Allow `ec2:StartInstances`, `ec2:DescribeInstances`, `logs:CreateLogGroup`

**Lambda Code:**
```python
import json
import boto3
import os

ec2 = boto3.client('ec2')
INSTANCE_ID = os.environ['JENKINS_INSTANCE_ID']  # Set in Lambda env vars

def lambda_handler(event, context):
    """
    Start Jenkins EC2 instance when PR is created/updated
    Triggered by GitHub webhook via API Gateway
    """
    
    # Parse GitHub webhook payload
    try:
        github_event = event.get('headers', {}).get('X-GitHub-Event', '')
        
        # Only process pull_request events
        if github_event != 'pull_request':
            return {
                'statusCode': 200,
                'body': json.dumps('Event ignored: ' + github_event)
            }
        
        body = json.loads(event.get('body', '{}'))
        action = body.get('action', '')
        
        # Start instance on PR opened, synchronize, or reopened
        if action in ['opened', 'synchronize', 'reopened']:
            # Check if instance is already running
            response = ec2.describe_instances(InstanceIds=[INSTANCE_ID])
            state = response['Reservations'][0]['Instances'][0]['State']['Name']
            
            if state == 'stopped':
                # Start the instance
                ec2.start_instances(InstanceIds=[INSTANCE_ID])
                
                # Wait for instance to be running
                ec2.get_waiter('instance_running').wait(InstanceIds=[INSTANCE_ID])
                
                return {
                    'statusCode': 200,
                    'body': json.dumps(f'Jenkins instance {INSTANCE_ID} started successfully')
                }
            elif state == 'running':
                return {
                    'statusCode': 200,
                    'body': json.dumps('Jenkins instance already running')
                }
            else:
                return {
                    'statusCode': 500,
                    'body': json.dumps(f'Instance in unexpected state: {state}')
                }
        else:
            return {
                'statusCode': 200,
                'body': json.dumps(f'PR action "{action}" - no action needed')
            }
            
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }
```

#### Lambda IAM Policy:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:StartInstances",
                "ec2:StopInstances",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus"
            ],
            "Resource": "arn:aws:ec2:REGION:ACCOUNT_ID:instance/INSTANCE_ID"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
```

---

### Step 4: Create API Gateway (Webhook Endpoint)

**Create REST API:**
1. Go to API Gateway → Create API → REST API
2. Create resource: `/webhook`
3. Create POST method → Integration type: Lambda Function
4. Select your Lambda function
5. Deploy API → Create stage (e.g., `prod`)
6. Copy the **Invoke URL** (e.g., `https://abc123.execute-api.us-east-1.amazonaws.com/prod/webhook`)

---

### Step 5: Configure GitHub Webhook

**In your GitHub repository:**
1. Settings → Webhooks → Add webhook
2. **Payload URL**: `https://abc123.execute-api.us-east-1.amazonaws.com/prod/webhook`
3. **Content type**: `application/json`
4. **Events**: Select "Pull requests"
5. **Active**: ✓

---

## Alternative: Simpler Approach with GitHub Actions

**Instead of Lambda, use GitHub Actions to start EC2:**

```yaml
# .github/workflows/start-jenkins.yml
name: Start Jenkins on PR

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  start-jenkins:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Check Jenkins instance status
        id: check-status
        run: |
          STATUS=$(aws ec2 describe-instances \
            --instance-ids ${{ secrets.JENKINS_INSTANCE_ID }} \
            --query 'Reservations[0].Instances[0].State.Name' \
            --output text)
          echo "status=$STATUS" >> $GITHUB_OUTPUT

      - name: Start Jenkins instance if stopped
        if: steps.check-status.outputs.status == 'stopped'
        run: |
          aws ec2 start-instances \
            --instance-ids ${{ secrets.JENKINS_INSTANCE_ID }}
          
          echo "⏳ Waiting for Jenkins to be ready..."
          aws ec2 wait instance-running \
            --instance-ids ${{ secrets.JENKINS_INSTANCE_ID }}
          
          # Wait for Jenkins to fully start (web UI ready)
          echo "⏳ Waiting for Jenkins web UI..."
          for i in {1..60}; do
            if curl -s -o /dev/null -w "%{http_code}" \
              http://${{ secrets.JENKINS_IP }}:8080 | grep -q "200\|403"; then
              echo "✅ Jenkins is ready!"
              break
            fi
            sleep 5
          done

      - name: Trigger Jenkins build
        run: |
          # Optionally trigger a build via Jenkins API
          JENKINS_URL="http://${{ secrets.JENKINS_IP }}:8080"
          CRUMB=$(curl -s -u "${{ secrets.JENKINS_USER }}:${{ secrets.JENKINS_TOKEN }}" \
            "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
          
          curl -X POST \
            -u "${{ secrets.JENKINS_USER }}:${{ secrets.JENKINS_TOKEN }}" \
            -H "$CRUMB" \
            "$JENKINS_URL/job/your-job-name/build?token=${{ secrets.JENKINS_TOKEN }}"
```

**Pros of GitHub Actions approach:**
- ✅ Simpler (no Lambda/API Gateway)
- ✅ Uses existing GitHub Actions infrastructure
- ✅ Easier to debug

**Cons:**
- ❌ Requires AWS credentials in GitHub secrets
- ❌ Slightly slower (runs in GitHub Actions runner)

---

## Cost Savings Comparison

### 24/7 Jenkins:
- **EC2 t3.medium**: $30/month (running 24/7)
- **EBS + Data**: ~$10/month
- **Total**: **$40/month = $480/year**

### On-Demand Jenkins:
**Assumptions:**
- 20 PRs/month
- 2 builds per PR
- 15 min/build = 30 min per PR
- 10 min startup time per PR
- Total runtime: ~13 hours/month (20 PRs × 40 min)

**Costs:**
- **EC2 runtime**: $30/month × (13/730) = **$0.53/month**
- **EBS storage**: $5/month (always charged)
- **Data transfer**: $2/month
- **Lambda**: **Free** (within free tier)
- **API Gateway**: **Free** (first 1M requests)
- **Total**: **~$7.50/month = $90/year**

**Savings: 88%** ($480 → $90 = $390/year saved!) 💰

---

## Auto-Stop Configuration

### Option 1: Time-Based (Simple)
Stop after X minutes of inactivity:
```bash
IDLE_TIMEOUT=900  # 15 minutes
```

### Option 2: Build-Based (Better)
Stop after last build completes + idle period:
```bash
# Wait for builds to complete, then idle timeout
```

### Option 3: Scheduled Stop
Always stop at end of day:
```bash
# Cron job to stop at 6 PM
0 18 * * * /usr/local/bin/stop-jenkins.sh
```

---

## Monitoring & Notifications

**Add CloudWatch alarms:**
```bash
# Alert if instance runs > 2 hours (might be stuck)
aws cloudwatch put-metric-alarm \
  --alarm-name jenkins-long-running \
  --alarm-description "Alert if Jenkins runs > 2 hours" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 24
```

---

## Troubleshooting

### Instance won't start:
- Check Lambda logs in CloudWatch
- Verify IAM permissions
- Check EC2 instance status

### Instance won't stop:
- Check auto-stop script logs: `sudo journalctl -u jenkins-auto-stop -f`
- Verify AWS CLI credentials on EC2
- Check IAM role permissions

### Jenkins not ready when build starts:
- Increase wait time in startup script
- Use health check endpoint: `/healthCheck`
- Add retry logic in Lambda/GitHub Actions

---

## Complete Setup Script

**Quick setup script for EC2:**
```bash
#!/bin/bash
# Run this on your EC2 instance after Jenkins installation

# Install dependencies
sudo apt update
sudo apt install -y awscli jq

# Create auto-stop script (paste script from above)
sudo nano /opt/jenkins-auto-stop.sh

# Create systemd service (paste service from above)
sudo nano /etc/systemd/system/jenkins-auto-stop.service

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable jenkins-auto-stop.service
sudo systemctl start jenkins-auto-stop.service

# Verify it's running
sudo systemctl status jenkins-auto-stop.service
```

---

## Recommendation

**Use the GitHub Actions approach** - it's simpler and doesn't require Lambda/API Gateway setup.

**Setup time:**
- EC2 instance: 30 minutes
- Auto-stop script: 15 minutes
- GitHub Actions workflow: 10 minutes
- **Total: ~1 hour**

**Monthly cost: $7.50 instead of $40 = Save $32.50/month!** 💰

