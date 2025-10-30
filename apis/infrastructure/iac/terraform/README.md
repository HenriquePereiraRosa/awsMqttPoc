# AWS MQTT POC Infrastructure - Clean Architecture

This Terraform configuration follows **clean architecture principles** with independent services, just like your Java microservices.

## 🏗️ **Clean Architecture Structure**

```
terraform/
├── shared/                    # Shared Infrastructure (Like common-domain)
│   └── networking/           # VPC, subnets, security groups
├── services/                 # Independent Services (Like microservices)
│   ├── mqtt/                # MQTT Service (Independent)
│   ├── kafka/               # Kafka Service (Independent)
│   └── springboot/          # Spring Boot Service (Independent)
├── environments/             # Environment Configs (Like profiles)
│   ├── dev/
│   ├── staging/
│   └── prod/
└── aws.config/              # AWS configuration
    └── iam.policy.json      # IAM policy for cicd_bot
```

## 🚀 **Deploy Services Independently**

### **1. Deploy Shared Infrastructure First**
```bash
cd shared/networking
terraform init
terraform plan
terraform apply
```

### **2. Deploy MQTT Service Only**
```bash
cd services/mqtt
terraform init
terraform plan
terraform apply
```

### **3. Add Other Services Later**
```bash
# Add Kafka when needed
cd services/kafka
terraform init
terraform plan
terraform apply

# Add Spring Boot when needed
cd services/springboot
terraform init
terraform plan
terraform apply
```

## 💰 **Cost Management**

### **MQTT Service Only**
- AWS IoT Core: ~$0.50/month
- Shared VPC: Free
- **Total**: ~$0.50/month

### **Add Kafka Service**
- MSK Cluster: ~$15/month
- **Total**: ~$15.50/month

### **Add Spring Boot Service**
- EKS Cluster: ~$73/month
- **Total**: ~$88.50/month

## 🏷️ **Tagging Strategy**

All resources tagged with:
- **Project**: `awsmqttpoc`
- **Service**: `mqtt`, `kafka`, `springboot`, `shared`
- **Component**: `mqtt-broker`, `kafka-broker`, `springboot-app`, `networking`
- **Environment**: `dev`, `staging`, `prod`

## 🎯 **Benefits (Like Java Microservices)**

1. **Independent Deployment**: Deploy only what you need
2. **Shared Infrastructure**: Common VPC, networking, security
3. **Environment Isolation**: Dev, staging, prod configs
4. **Cost Optimization**: Pay only for what you deploy
5. **Team Ownership**: Each team can own their service

## 🔧 **Quick Start**

1. **Deploy Shared Infrastructure**: `cd shared/networking && terraform apply`
2. **Deploy MQTT Service**: `cd services/mqtt && terraform apply`
3. **Test MQTT**: Connect to AWS IoT Core endpoint
4. **Add Services Later**: Deploy Kafka, Spring Boot when needed

This gives you the same benefits as your Java microservices: independent deployment, shared infrastructure, and cost optimization! 🎉