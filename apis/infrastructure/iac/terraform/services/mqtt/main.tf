# MQTT Service - Independent Deployment
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
    key    = "services/mqtt/terraform.tfstate"
    region = "us-east-1"
    profile = "cicd_bot"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Data sources - reading remote state from S3
data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "shared/networking/terraform.tfstate"
    region = var.aws_region
    profile = var.aws_profile
  }
}

# Local values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Service     = "mqtt"
    Component   = "mqtt-broker"
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = "mqtt-poc"
    Purpose     = "mqtt-infrastructure"
    Performance = "analysis"
  }
}

# MQTT Service Resources
resource "aws_iot_thing" "mqtt_client" {
  name = "${var.project_name}-${var.environment}-mqtt-client"
}

resource "aws_iot_thing_principal_attachment" "mqtt_client_attachment" {
  principal = aws_iot_certificate.mqtt_cert.arn
  thing     = aws_iot_thing.mqtt_client.name
}

resource "aws_iot_policy" "mqtt_policy" {
  name = "${var.project_name}-${var.environment}-mqtt-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Connect",
          "iot:Publish",
          "iot:Subscribe",
          "iot:Receive"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iot_certificate" "mqtt_cert" {
  active = true
}

resource "aws_iot_policy_attachment" "mqtt_policy_attachment" {
  policy = aws_iot_policy.mqtt_policy.name
  target = aws_iot_certificate.mqtt_cert.arn
}

data "aws_iot_endpoint" "iot_endpoint" {
  endpoint_type = "iot:Data-ATS"
}


# MQTT Service Monitoring
resource "aws_cloudwatch_dashboard" "mqtt" {
  dashboard_name = "${var.project_name}-${var.environment}-mqtt-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          region = var.aws_region
          title  = "MQTT Messages (All Clients)"
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
          metrics = [
            [
              {
                "expression": "SEARCH('{AWS/IoT,MetricName=MessagesPublished}', 'Sum', 300)",
                "label": "MessagesPublished (all)",
                "id": "e1"
              }
            ],
            [
              {
                "expression": "SEARCH('{AWS/IoT,MetricName=MessagesReceived}', 'Sum', 300)",
                "label": "MessagesReceived (all)",
                "id": "e2"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          region = var.aws_region
          title  = "MQTT Messages by ClientId"
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
          metrics = [
            [
              {
                "expression": "SEARCH('{AWS/IoT,MetricName=MessagesPublished,ClientId=*}', 'Sum', 300)",
                "label": "MessagesPublished by ClientId",
                "id": "e3"
              }
            ],
            [
              {
                "expression": "SEARCH('{AWS/IoT,MetricName=MessagesReceived,ClientId=*}', 'Sum', 300)",
                "label": "MessagesReceived by ClientId",
                "id": "e4"
              }
            ]
          ]
        }
      }
    ]
  })
}

