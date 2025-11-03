# Jenkins CI/CD Server - Terraform Module

This module provisions a Jenkins CI/CD server on EC2 with auto-stop functionality.

## Features

- ✅ **Auto-stop**: Stops instance after 15 minutes of inactivity (configurable)
- ✅ **Auto-install**: Jenkins automatically installed and configured via user data
- ✅ **IAM Role**: Instance can stop itself (no need for separate credentials)
- ✅ **Elastic IP**: Optional static IP (recommended)
- ✅ **Security**: Security groups configured for Jenkins web UI (8080) and SSH (22)

## Prerequisites

1. Networking infrastructure must be deployed first
   ```bash
   cd ../shared/networking
   terraform init
   terraform apply
   ```

2. AWS credentials configured with `cicd_bot` profile

## Usage

### 1. Initialize Terraform

```bash
cd apis/infrastructure/iac/terraform/services/jenkins
terraform init
```

### 2. Configure Variables

The Jenkins module uses its own `terraform.tfvars` file (located in this directory) which contains only variables relevant to Jenkins.

**For Dev Environment:**
```bash
# terraform.tfvars is already configured for dev
# Just run terraform apply - it will automatically use terraform.tfvars in the same directory
terraform apply
```

**For other environments:**
Create environment-specific tfvars files (e.g., `terraform.tfvars.prod`) or use environment variables (`TF_VAR_*`).

**Note**: Each module should have its own tfvars file to avoid warnings about undeclared variables. Use shared/environment tfvars only when variables are truly shared across multiple modules.

### 3. Deploy Jenkins

```bash
terraform plan
terraform apply
```

### 4. Get Jenkins Details

After deployment, get the instance ID and URL:

```bash
# Get instance ID
terraform output jenkins_instance_id

# Get Jenkins URL
terraform output jenkins_url

# Get initial admin password (if you have SSH access)
terraform output jenkins_initial_admin_password_command
```

## Outputs

| Output | Description |
|--------|-------------|
| `jenkins_instance_id` | EC2 instance ID (for GitHub Secrets) |
| `jenkins_public_ip` | Public IP address |
| `jenkins_url` | Jenkins web UI URL (http://IP:8080) |
| `jenkins_iam_role_arn` | IAM role ARN |

## GitHub Secrets

After deployment, add these to GitHub Secrets:

1. `JENKINS_INSTANCE_ID` = `terraform output -raw jenkins_instance_id`
2. `JENKINS_USER` = `admin` (default Jenkins username)
3. `JENKINS_TOKEN` = Create in Jenkins UI
4. `JENKINS_BUILD_TOKEN` = Configure in Jenkins job
5. `JENKINS_JOB_NAME` = Your Jenkins pipeline name

## Accessing Jenkins

1. Get the URL:
   ```bash
   terraform output jenkins_url
   ```

2. Open in browser: `http://YOUR_IP:8080`

3. Get initial admin password:
   - If you have SSH key: `ssh ubuntu@IP 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'`
   - Or check: `/var/log/jenkins-setup.log` on the instance

4. Complete Jenkins setup wizard

## Auto-Stop Configuration

Jenkins automatically stops after **15 minutes of inactivity** (no builds running or queued).

To change timeout, modify `jenkins_idle_timeout` in `terraform.tfvars`:
```hcl
jenkins_idle_timeout = 1800  # 30 minutes
```

## Security Notes

⚠️ **Important:** Default security group allows access from `0.0.0.0/0` (anywhere).

For production, restrict access:
1. Edit `main.tf` → `aws_security_group.jenkins`
2. Change `cidr_blocks` to your IP: `["YOUR_IP/32"]`

Or add your IP to the security group:
```bash
aws ec2 authorize-security-group-ingress \
  --group-id $(terraform output -raw jenkins_security_group_id) \
  --protocol tcp \
  --port 8080 \
  --cidr YOUR_IP/32 \
  --profile cicd_bot
```

## Cost Optimization

- **Instance type**: `t3.medium` (~$30/month if running 24/7)
- **With auto-stop**: ~$7.50/month (only pays when running)
- **Storage**: 30GB EBS (~$3/month)

## Troubleshooting

### Jenkins not accessible

1. Check security group allows port 8080
2. Check instance is running: `aws ec2 describe-instances --instance-ids INSTANCE_ID`
3. Check Jenkins is started: `ssh ubuntu@IP 'sudo systemctl status jenkins'`

### Auto-stop not working

1. Check service: `ssh ubuntu@IP 'sudo systemctl status jenkins-auto-stop'`
2. Check logs: `ssh ubuntu@IP 'sudo journalctl -u jenkins-auto-stop -f'`
3. Verify IAM role has permissions

### Getting initial password

If you don't have SSH access, use AWS Systems Manager Session Manager:
```bash
aws ssm start-session --target INSTANCE_ID --document-name AWS-StartInteractiveCommand --parameters command='sudo cat /var/lib/jenkins/secrets/initialAdminPassword'
```

## Cleanup

To destroy Jenkins:
```bash
terraform destroy
```

⚠️ **Warning:** This will delete the Jenkins instance and all data. Backup important configurations first!

