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

