# Deploy MQTT Service Script (PowerShell)
# This script deploys only the MQTT service for daily development

Write-Host "🚀 Deploying MQTT Service - Development Mode" -ForegroundColor Blue
Write-Host "===========================================" -ForegroundColor Blue

# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Split-Path -Parent $ScriptDir

Write-Host "Terraform directory: $TerraformDir"
Write-Host ""

# Change to terraform directory
Set-Location $TerraformDir

# Deploy shared infrastructure first
Write-Host "1. Deploying shared networking infrastructure..." -ForegroundColor Blue
Set-Location shared/networking
terraform init
terraform plan
terraform apply -auto-approve
Write-Host "✅ Shared networking deployed" -ForegroundColor Green
Write-Host ""

# Deploy MQTT service
Write-Host "2. Deploying MQTT service..." -ForegroundColor Blue
Set-Location ../../services/mqtt
terraform init
terraform plan
terraform apply -auto-approve
Write-Host "✅ MQTT service deployed" -ForegroundColor Green
Write-Host ""

# Show outputs
Write-Host "📊 MQTT Service Information:" -ForegroundColor Yellow
Write-Host "MQTT Endpoint: $(terraform output -raw mqtt_endpoint)"
Write-Host "MQTT Thing Name: $(terraform output -raw mqtt_thing_name)"
Write-Host "Dashboard URL: $(terraform output -raw mqtt_dashboard_url)"
Write-Host ""

Write-Host "🎉 MQTT Service ready for development!" -ForegroundColor Green
Write-Host "💡 To destroy at end of day: .\scripts\destroy-all.ps1" -ForegroundColor Yellow
Write-Host "💰 Estimated cost: ~`$0.50/month" -ForegroundColor Yellow




