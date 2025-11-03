variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "awsmqttpoc"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS profile to use"
  type        = string
  default     = "cicd_bot"
}

variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "t3.medium"
}

variable "jenkins_volume_size" {
  description = "Root volume size in GB for Jenkins instance"
  type        = number
  default     = 30
}

variable "jenkins_idle_timeout" {
  description = "Idle timeout in seconds before auto-stopping Jenkins (900 = 15 minutes)"
  type        = number
  default     = 900
}

variable "key_pair_name" {
  description = "AWS Key Pair name for SSH access (optional - leave empty if not needed)"
  type        = string
  default     = ""
}

variable "assign_elastic_ip" {
  description = "Whether to assign an Elastic IP to Jenkins (keeps same IP when stopped/started)"
  type        = bool
  default     = true
}

variable "encrypt_ebs" {
  description = "Whether to encrypt EBS volumes (requires KMS permissions if true)"
  type        = bool
  default     = false  # Set to false for dev to avoid KMS permission issues
}

# ============================================================================
# Non-Security Variables (can be in terraform.tfvars)
# ============================================================================

variable "jenkins_port" {
  description = "Port for Jenkins web UI"
  type        = number
  default     = 8080
}

variable "ebs_volume_type" {
  description = "EBS volume type (gp3, gp2, io1, etc.)"
  type        = string
  default     = "gp3"
}

variable "auto_stop_check_interval" {
  description = "Auto-stop check interval in seconds"
  type        = number
  default     = 60
}

variable "terraform_state_bucket" {
  description = "S3 bucket name for Terraform state (used in remote state config)"
  type        = string
  default     = "awsmqttpoc-terraform-state"
}

variable "terraform_state_key" {
  description = "S3 key path for Terraform state (used in remote state config)"
  type        = string
  default     = "shared/networking/terraform.tfstate"
}

# ============================================================================
# Security-Sensitive Variables (MUST be set via env vars or .tfvars.local)
# DO NOT commit these to terraform.tfvars!
# ============================================================================

variable "jenkins_web_cidr_blocks" {
  description = "CIDR blocks allowed to access Jenkins web UI. For dev: set in environments/dev/terraform.tfvars. For prod: use TF_VAR_jenkins_web_cidr_blocks env var"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # ⚠️ Default permissive - override in dev tfvars or prod env vars
}

variable "jenkins_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to Jenkins. For dev: set in environments/dev/terraform.tfvars. For prod: use TF_VAR_jenkins_ssh_cidr_blocks env var"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # ⚠️ Default permissive - override in dev tfvars or prod env vars
}

