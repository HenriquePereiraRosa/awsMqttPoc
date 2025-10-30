# Shared Networking Infrastructure
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
    key    = "shared/networking/terraform.tfstate"
    region = "us-east-1"
    profile = "cicd_bot"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Local values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Service     = "shared"
    Component   = "networking"
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = "shared-infrastructure"
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC and Networking
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

resource "aws_subnet" "public" {
  count = var.availability_zones_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Type = "public"
  })
}

resource "aws_subnet" "private" {
  count = var.availability_zones_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-subnet-${count.index + 1}"
    Type = "private"
  })
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = var.availability_zones_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Groups
resource "aws_security_group" "mqtt" {
  name_prefix = "${var.project_name}-${var.environment}-mqtt"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 8883
    to_port     = 8883
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "MQTT over TLS"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-mqtt-sg"
    Service = "mqtt"
    Component = "mqtt-broker"
  })
}

resource "aws_security_group" "kafka" {
  name_prefix = "${var.project_name}-${var.environment}-kafka"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Kafka Broker"
  }

  ingress {
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Kafka Broker TLS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-kafka-sg"
    Service = "kafka"
    Component = "kafka-broker"
  })
}

resource "aws_security_group" "springboot" {
  name_prefix = "${var.project_name}-${var.environment}-springboot"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Spring Boot Application"
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "Spring Boot HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-springboot-sg"
    Service = "springboot"
    Component = "springboot-app"
  })
}

