# Infrastructure Management Scripts

This directory contains scripts for daily infrastructure management and cost control.

## 🚀 **Available Scripts**

### **Daily Workflow (Interactive Menu)**
```bash
# Linux/Mac/WSL
./daily-workflow.sh

# Windows PowerShell
.\daily-workflow.ps1
```

### **Quick Deploy MQTT Service**
```bash
# Linux/Mac/WSL
./deploy-mqtt.sh

# Windows PowerShell
.\deploy-mqtt.ps1
```

### **Destroy All Infrastructure (End of Day)**
```bash
# Linux/Mac/WSL
./destroy-all.sh

# Windows PowerShell
.\destroy-all.ps1 -Force
```

## 🎯 **Daily Workflow**

### **Start of Day**
```bash
# Option 1: Interactive menu
./daily-workflow.sh

# Option 2: Quick deploy MQTT only
./deploy-mqtt.sh
```

### **End of Day**
```bash
# Destroy everything to save costs
./destroy-all.sh
```

## 💰 **Cost Control**

### **Cost Estimates**
- **MQTT Only**: ~$0.50/month
- **MQTT + Kafka**: ~$15.50/month
- **MQTT + Kafka + Spring Boot**: ~$88.50/month

### **Cost Control Strategy**
1. **Deploy only what you need**
2. **Destroy everything at end of day**
3. **Monitor costs with AWS Cost Explorer**
4. **Use budget alerts**

## 🔧 **Script Features**

### **Destroy All Script**
- Destroys services in reverse dependency order
- Checks for existing state before destroying
- Provides colored output for clarity
- Shows cost savings confirmation

### **Deploy MQTT Script**
- Deploys shared networking first
- Deploys MQTT service
- Shows connection information
- Provides cost estimate

### **Daily Workflow Script**
- Interactive menu for all operations
- Shows infrastructure status
- Displays cost information
- Easy navigation

## 🚨 **Important Notes**

### **Before Running Scripts**
1. Ensure Terraform is installed
2. Configure AWS credentials (`cicd_bot` profile)
3. Run from the terraform directory

### **Safety Features**
- Confirmation prompts for destructive operations
- State file checks before operations
- Colored output for clarity
- Error handling

## 🎯 **Quick Start**

### **1. First Time Setup**
```bash
cd apis/infrastructure/iac/terraform
chmod +x scripts/*.sh  # Linux/Mac only
```

### **2. Daily Routine**
```bash
# Morning: Deploy what you need
./scripts/daily-workflow.sh

# Evening: Destroy everything
./scripts/destroy-all.sh
```

### **3. Emergency Destroy**
```bash
# Force destroy without confirmation
./scripts/destroy-all.sh --force
```

## 📊 **Monitoring**

### **Check Status**
```bash
./scripts/daily-workflow.sh
# Select option 5: Show Infrastructure Status
```

### **View Costs**
```bash
./scripts/daily-workflow.sh
# Select option 7: Show Cost Information
```

This gives you complete control over your infrastructure costs while maintaining development productivity! 🎉




