# Daily Workflow Script (PowerShell)
# This script provides a menu for daily infrastructure management

function Show-Menu {
    Write-Host "🏗️  AWS MQTT POC - Daily Infrastructure Management" -ForegroundColor Magenta
    Write-Host "================================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "1. Deploy MQTT Service (Start of day)" -ForegroundColor Blue
    Write-Host "2. Deploy Kafka Service" -ForegroundColor Blue
    Write-Host "3. Deploy Spring Boot Service" -ForegroundColor Blue
    Write-Host "4. Deploy All Services" -ForegroundColor Blue
    Write-Host "5. Show Infrastructure Status" -ForegroundColor Blue
    Write-Host "6. Destroy All Infrastructure (End of day)" -ForegroundColor Blue
    Write-Host "7. Show Cost Information" -ForegroundColor Blue
    Write-Host "8. Exit" -ForegroundColor Blue
    Write-Host ""
}

function Show-Status {
    Write-Host "📊 Infrastructure Status:" -ForegroundColor Yellow
    Write-Host ""
    
    # Check shared networking
    if (Test-Path "shared/networking") {
        Push-Location "shared/networking"
        if (Test-Path "terraform.tfstate") {
            Write-Host "  ✅ Shared Networking: Deployed" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Shared Networking: Not deployed" -ForegroundColor Yellow
        }
        Pop-Location
    }
    
    # Check MQTT service
    if (Test-Path "services/mqtt") {
        Push-Location "services/mqtt"
        if (Test-Path "terraform.tfstate") {
            Write-Host "  ✅ MQTT Service: Deployed" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  MQTT Service: Not deployed" -ForegroundColor Yellow
        }
        Pop-Location
    }
    
    # Check Kafka service
    if (Test-Path "services/kafka") {
        Push-Location "services/kafka"
        if (Test-Path "terraform.tfstate") {
            Write-Host "  ✅ Kafka Service: Deployed" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Kafka Service: Not deployed" -ForegroundColor Yellow
        }
        Pop-Location
    }
    
    # Check Spring Boot service
    if (Test-Path "services/springboot") {
        Push-Location "services/springboot"
        if (Test-Path "terraform.tfstate") {
            Write-Host "  ✅ Spring Boot Service: Deployed" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Spring Boot Service: Not deployed" -ForegroundColor Yellow
        }
        Pop-Location
    }
    
    Write-Host ""
}

function Show-Cost {
    Write-Host "💰 Cost Information:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  MQTT Service Only: ~`$0.50/month" -ForegroundColor Blue
    Write-Host "  MQTT + Kafka: ~`$15.50/month" -ForegroundColor Blue
    Write-Host "  MQTT + Kafka + Spring Boot: ~`$88.50/month" -ForegroundColor Blue
    Write-Host ""
    Write-Host "💡 Cost Control:" -ForegroundColor Yellow
    Write-Host "  - Use 'Destroy All' at end of day"
    Write-Host "  - Deploy only what you need"
    Write-Host "  - Monitor with AWS Cost Explorer"
    Write-Host ""
}

# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Split-Path -Parent $ScriptDir

# Change to terraform directory
Set-Location $TerraformDir

# Main menu loop
while ($true) {
    Clear-Host
    Show-Menu
    $choice = Read-Host "Select an option (1-8)"
    
    switch ($choice) {
        "1" {
            Write-Host "Deploying MQTT Service..." -ForegroundColor Blue
            .\scripts\deploy-mqtt.ps1
        }
        "2" {
            Write-Host "Deploying Kafka Service..." -ForegroundColor Blue
            Write-Host "Kafka deployment not implemented yet"
        }
        "3" {
            Write-Host "Deploying Spring Boot Service..." -ForegroundColor Blue
            Write-Host "Spring Boot deployment not implemented yet"
        }
        "4" {
            Write-Host "Deploying All Services..." -ForegroundColor Blue
            Write-Host "Full deployment not implemented yet"
        }
        "5" {
            Show-Status
        }
        "6" {
            Write-Host "Destroying All Infrastructure..." -ForegroundColor Red
            .\scripts\destroy-all.ps1
        }
        "7" {
            Show-Cost
        }
        "8" {
            Write-Host "Goodbye! 👋" -ForegroundColor Green
            exit 0
        }
        default {
            Write-Host "Invalid option. Please select 1-8." -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}




