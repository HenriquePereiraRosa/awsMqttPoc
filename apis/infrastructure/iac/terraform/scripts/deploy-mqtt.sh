#!/bin/bash

# Deploy MQTT Service Script
# This script deploys only the MQTT service for daily development

set -e  # Exit on any error

echo "🚀 Deploying MQTT Service - Development Mode"
echo "==========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")"

echo "Terraform directory: $TERRAFORM_DIR"
echo ""

# Change to terraform directory
cd "$TERRAFORM_DIR"

# Deploy shared infrastructure first
echo -e "${BLUE}1. Deploying shared networking infrastructure...${NC}"
cd shared/networking
terraform init
terraform plan
terraform apply -auto-approve
echo -e "${GREEN}✅ Shared networking deployed${NC}"
echo ""

# Deploy MQTT service
echo -e "${BLUE}2. Deploying MQTT service...${NC}"
cd ../../services/mqtt
terraform init
terraform plan
terraform apply -auto-approve
echo -e "${GREEN}✅ MQTT service deployed${NC}"
echo ""

# Show outputs
echo -e "${YELLOW}📊 MQTT Service Information:${NC}"
echo "MQTT Endpoint: $(terraform output -raw mqtt_endpoint)"
echo "MQTT Thing Name: $(terraform output -raw mqtt_thing_name)"
echo "Dashboard URL: $(terraform output -raw mqtt_dashboard_url)"
echo ""

echo -e "${GREEN}🎉 MQTT Service ready for development!${NC}"
echo -e "${YELLOW}💡 To destroy at end of day: ./scripts/destroy-all.sh${NC}"
echo -e "${YELLOW}💰 Estimated cost: ~$0.50/month${NC}"




