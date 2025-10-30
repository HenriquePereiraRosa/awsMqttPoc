variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "awsmqttpoc"
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

variable "bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "awsmqttpoc-terraform-state"
}




