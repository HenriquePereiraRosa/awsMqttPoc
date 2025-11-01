# Jenkins CI/CD Server on EC2
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "awsmqttpoc-terraform-state"
    key    = "services/jenkins/terraform.tfstate"
    region = "us-east-1"
    profile = "cicd_bot"
  }
}

# Get remote state from networking
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "awsmqttpoc-terraform-state"
    key    = "shared/networking/terraform.tfstate"
    region = "us-east-1"
    profile = "cicd_bot"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Get latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hub/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for Jenkins EC2 (allows auto-stop)
resource "aws_iam_role" "jenkins_ec2_role" {
  name = "${var.project_name}-${var.environment}-jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins-ec2-role"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# IAM Policy for Jenkins to stop itself
resource "aws_iam_role_policy" "jenkins_auto_stop" {
  name = "${var.project_name}-${var.environment}-jenkins-auto-stop"
  role = aws_iam_role.jenkins_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:StopInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to get instance metadata
resource "aws_iam_role_policy_attachment" "jenkins_ssm" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance Profile
resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.project_name}-${var.environment}-jenkins-profile"
  role = aws_iam_role.jenkins_ec2_role.name

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins-profile"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# User data script to install Jenkins and configure auto-stop
locals {
  user_data = <<-EOF
#!/bin/bash
set -e

# Update system
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y \
  openjdk-21-jdk \
  curl \
  wget \
  git \
  docker.io \
  awscli \
  jq \
  ec2-instance-connect

# Add jenkins user to docker group
usermod -aG docker ubuntu

# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update
apt-get install -y jenkins

# Start and enable Jenkins
systemctl start jenkins
systemctl enable jenkins

# Install AWS CLI v2 (if not already installed)
if ! command -v aws &> /dev/null; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  apt-get install -y unzip
  unzip awscliv2.zip
  ./aws/install
  rm -rf aws awscliv2.zip
fi

# Configure AWS CLI to use instance profile
mkdir -p /root/.aws
cat > /root/.aws/config <<'AWSCONFIG'
[default]
region = ${var.aws_region}
AWSCONFIG

# Create auto-stop script
cat > /opt/jenkins-auto-stop.sh <<'AUTOSTOP'
#!/bin/bash
IDLE_TIMEOUT=${var.jenkins_idle_timeout}
CHECK_INTERVAL=60

INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
REGION=$(ec2-metadata --availability-zone | cut -d " " -f 2 | sed 's/[a-z]$//')

while true; do
    sleep $CHECK_INTERVAL
    
    # Check if Jenkins has active builds
    ACTIVE_BUILDS=$(curl -s http://localhost:8080/computer/api/json 2>/dev/null | jq -r '.computer[0].executors[] | select(.currentExecutable != null) | .currentExecutable.url' | wc -l || echo "0")
    
    # Check if Jenkins has queued builds
    QUEUED_BUILDS=$(curl -s http://localhost:8080/queue/api/json 2>/dev/null | jq -r '.items | length' || echo "0")
    
    if [ "$ACTIVE_BUILDS" -gt 0 ] || [ "$QUEUED_BUILDS" -gt 0 ]; then
        echo "$(date): Active builds detected, resetting timer"
        continue
    fi
    
    # Check last activity (if no builds for timeout period, stop)
    LAST_ACTIVITY_FILE="/var/lib/jenkins/last_activity"
    CURRENT_TIME=$(date +%s)
    
    if [ -f "$LAST_ACTIVITY_FILE" ]; then
        LAST_ACTIVITY=$(cat "$LAST_ACTIVITY_FILE")
        IDLE_TIME=$((CURRENT_TIME - LAST_ACTIVITY))
        
        if [ $IDLE_TIME -ge $IDLE_TIMEOUT ]; then
            echo "$(date): No activity for $IDLE_TIME seconds, stopping instance"
            
            # Stop Jenkins gracefully
            systemctl stop jenkins
            
            # Stop EC2 instance
            aws ec2 stop-instances --instance-ids $INSTANCE_ID --region $REGION
            
            exit 0
        else
            echo "$(date): Idle for $IDLE_TIME seconds (timeout: $IDLE_TIMEOUT)"
        fi
    else
        # Update last activity file
        echo $CURRENT_TIME > "$LAST_ACTIVITY_FILE"
    fi
done
AUTOSTOP

chmod +x /opt/jenkins-auto-stop.sh

# Create systemd service for auto-stop
cat > /etc/systemd/system/jenkins-auto-stop.service <<'SYSTEMD'
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
SYSTEMD

# Enable and start auto-stop service (wait a bit for Jenkins to be ready)
sleep 30
systemctl daemon-reload
systemctl enable jenkins-auto-stop.service
systemctl start jenkins-auto-stop.service

# Log initial admin password
echo "=== Jenkins Setup Complete ===" >> /var/log/jenkins-setup.log
echo "Initial admin password:" >> /var/log/jenkins-setup.log
cat /var/lib/jenkins/secrets/initialAdminPassword >> /var/log/jenkins-setup.log
echo "" >> /var/log/jenkins-setup.log

# Wait for Jenkins to be fully ready
for i in {1..60}; do
    if curl -s http://localhost:8080 | grep -q "Jenkins"; then
        echo "Jenkins is ready!" >> /var/log/jenkins-setup.log
        break
    fi
    sleep 5
done
EOF
}

# Security group for Jenkins
resource "aws_security_group" "jenkins" {
  name        = "${var.project_name}-${var.environment}-jenkins-sg"
  description = "Security group for Jenkins CI/CD server"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id

  ingress {
    description = "Jenkins Web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to your IP in production: ["YOUR_IP/32"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to your IP in production
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins-sg"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# EC2 Instance for Jenkins
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.jenkins_instance_type
  key_name               = var.key_pair_name # Optional: if you want SSH access
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  subnet_id              = data.terraform_remote_state.networking.outputs.public_subnet_ids[0]
  iam_instance_profile   = aws_iam_instance_profile.jenkins.name
  user_data              = base64encode(local.user_data)

  root_block_device {
    volume_type = "gp3"
    volume_size = var.jenkins_volume_size
    encrypted   = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Purpose     = "ci-cd"
  }
}

# Elastic IP for Jenkins (optional - keeps same IP when stopped/started)
resource "aws_eip" "jenkins" {
  count  = var.assign_elastic_ip ? 1 : 0
  domain = "vpc"

  instance                  = aws_instance.jenkins.id
  associate_with_private_ip = aws_instance.jenkins.private_ip

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins-eip"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  depends_on = [aws_instance.jenkins]
}

