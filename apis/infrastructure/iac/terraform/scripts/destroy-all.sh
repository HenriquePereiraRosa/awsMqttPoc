#!/bin/bash

# Destroy All Infrastructure Script
# This script destroys all infrastructure to avoid costs when not in use

set -e  # Exit on any error

echo "🔥 Destroying All Infrastructure - Cost Control Mode"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to destroy a service
destroy_service() {
    local service_name=$1
    local service_path=$2
    
    echo -e "${YELLOW}Destroying $service_name...${NC}"
    
    if [ -d "$service_path" ]; then
        cd "$service_path"
        
        if [ -f "terraform.tfstate" ] || [ -f ".terraform/terraform.tfstate" ]; then
            echo "  - Found existing state, destroying..."
            terraform destroy -auto-approve
            echo -e "${GREEN}  ✅ $service_name destroyed successfully${NC}"
        else
            echo -e "${YELLOW}  ⚠️  No state found for $service_name (already destroyed or never created)${NC}"
        fi
        
        cd - > /dev/null
    else
        echo -e "${YELLOW}  ⚠️  Directory $service_path not found${NC}"
    fi
}

# Function to destroy shared infrastructure
destroy_shared() {
    local shared_name=$1
    local shared_path=$2
    
    echo -e "${YELLOW}Destroying shared $shared_name...${NC}"
    
    if [ -d "$shared_path" ]; then
        cd "$shared_path"
        
        if [ -f "terraform.tfstate" ] || [ -f ".terraform/terraform.tfstate" ]; then
            echo "  - Found existing state, destroying..."
            terraform destroy -auto-approve
            echo -e "${GREEN}  ✅ Shared $shared_name destroyed successfully${NC}"
        else
            echo -e "${YELLOW}  ⚠️  No state found for shared $shared_name${NC}"
        fi
        
        cd - > /dev/null
    else
        echo -e "${YELLOW}  ⚠️  Directory $shared_path not found${NC}"
    fi
}

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")"

echo "Terraform directory: $TERRAFORM_DIR"
echo ""

# Change to terraform directory
cd "$TERRAFORM_DIR"

# Destroy services (in reverse order of dependency)
echo -e "${RED}🚀 Starting destruction process...${NC}"
echo ""

# Destroy services
destroy_service "Spring Boot Service" "services/springboot"
destroy_service "Kafka Service" "services/kafka"
destroy_service "MQTT Service" "services/mqtt"

echo ""

# Destroy shared infrastructure
destroy_shared "Networking" "shared/networking"

echo ""
echo -e "${GREEN}🎉 All infrastructure destroyed successfully!${NC}"
echo -e "${GREEN}💰 Cost control: No AWS resources running${NC}"
echo ""
echo -e "${YELLOW}💡 To redeploy tomorrow:${NC}"
echo "  1. cd shared/networking && terraform apply"
echo "  2. cd services/mqtt && terraform apply"
echo "  3. Add other services as needed"
echo ""
echo -e "${GREEN}Good night! 🌙${NC}"




