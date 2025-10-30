variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "awsmqttpoc"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
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

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "cicd_bot"
}

variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = "awsmqttpoc-terraform-state"
}

