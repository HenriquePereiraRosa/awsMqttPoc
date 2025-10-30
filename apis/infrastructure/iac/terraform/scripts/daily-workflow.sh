#!/bin/bash

# Daily Workflow Script
# This script provides a menu for daily infrastructure management

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")"

# Function to show menu
show_menu() {
    echo -e "${PURPLE}🏗️  AWS MQTT POC - Daily Infrastructure Management${NC}"
    echo -e "${PURPLE}================================================${NC}"
    echo ""
    echo -e "${BLUE}1.${NC} Deploy MQTT Service (Start of day)"
    echo -e "${BLUE}2.${NC} Deploy Kafka Service"
    echo -e "${BLUE}3.${NC} Deploy Spring Boot Service"
    echo -e "${BLUE}4.${NC} Deploy All Services"
    echo -e "${BLUE}5.${NC} Show Infrastructure Status"
    echo -e "${BLUE}6.${NC} Destroy All Infrastructure (End of day)"
    echo -e "${BLUE}7.${NC} Show Cost Information"
    echo -e "${BLUE}8.${NC} Exit"
    echo ""
}

# Function to show status
show_status() {
    echo -e "${YELLOW}📊 Infrastructure Status:${NC}"
    echo ""
    
    # Check shared networking
    if [ -d "$TERRAFORM_DIR/shared/networking" ]; then
        cd "$TERRAFORM_DIR/shared/networking"
        if [ -f "terraform.tfstate" ]; then
            echo -e "  ${GREEN}✅ Shared Networking: Deployed${NC}"
        else
            echo -e "  ${YELLOW}⚠️  Shared Networking: Not deployed${NC}"
        fi
        cd - > /dev/null
    fi
    
    # Check MQTT service
    if [ -d "$TERRAFORM_DIR/services/mqtt" ]; then
        cd "$TERRAFORM_DIR/services/mqtt"
        if [ -f "terraform.tfstate" ]; then
            echo -e "  ${GREEN}✅ MQTT Service: Deployed${NC}"
        else
            echo -e "  ${YELLOW}⚠️  MQTT Service: Not deployed${NC}"
        fi
        cd - > /dev/null
    fi
    
    # Check Kafka service
    if [ -d "$TERRAFORM_DIR/services/kafka" ]; then
        cd "$TERRAFORM_DIR/services/kafka"
        if [ -f "terraform.tfstate" ]; then
            echo -e "  ${GREEN}✅ Kafka Service: Deployed${NC}"
        else
            echo -e "  ${YELLOW}⚠️  Kafka Service: Not deployed${NC}"
        fi
        cd - > /dev/null
    fi
    
    # Check Spring Boot service
    if [ -d "$TERRAFORM_DIR/services/springboot" ]; then
        cd "$TERRAFORM_DIR/services/springboot"
        if [ -f "terraform.tfstate" ]; then
            echo -e "  ${GREEN}✅ Spring Boot Service: Deployed${NC}"
        else
            echo -e "  ${YELLOW}⚠️  Spring Boot Service: Not deployed${NC}"
        fi
        cd - > /dev/null
    fi
    
    echo ""
}

# Function to show cost information
show_cost() {
    echo -e "${YELLOW}💰 Cost Information:${NC}"
    echo ""
    echo -e "  ${BLUE}MQTT Service Only:${NC} ~$0.50/month"
    echo -e "  ${BLUE}MQTT + Kafka:${NC} ~$15.50/month"
    echo -e "  ${BLUE}MQTT + Kafka + Spring Boot:${NC} ~$88.50/month"
    echo ""
    echo -e "${YELLOW}💡 Cost Control:${NC}"
    echo "  - Use 'Destroy All' at end of day"
    echo "  - Deploy only what you need"
    echo "  - Monitor with AWS Cost Explorer"
    echo ""
}

# Main menu loop
while true; do
    show_menu
    read -p "Select an option (1-8): " choice
    
    case $choice in
        1)
            echo -e "${BLUE}Deploying MQTT Service...${NC}"
            ./scripts/deploy-mqtt.sh
            ;;
        2)
            echo -e "${BLUE}Deploying Kafka Service...${NC}"
            echo "Kafka deployment not implemented yet"
            ;;
        3)
            echo -e "${BLUE}Deploying Spring Boot Service...${NC}"
            echo "Spring Boot deployment not implemented yet"
            ;;
        4)
            echo -e "${BLUE}Deploying All Services...${NC}"
            echo "Full deployment not implemented yet"
            ;;
        5)
            show_status
            ;;
        6)
            echo -e "${RED}Destroying All Infrastructure...${NC}"
            ./scripts/destroy-all.sh
            ;;
        7)
            show_cost
            ;;
        8)
            echo -e "${GREEN}Goodbye! 👋${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please select 1-8.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    clear
done




