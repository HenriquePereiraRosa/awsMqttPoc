# Destroy All Infrastructure Script (PowerShell)
# This script destroys all infrastructure to avoid costs when not in use

param(
    [switch]$Force = $false
)

Write-Host "🔥 Destroying All Infrastructure - Cost Control Mode" -ForegroundColor Red
Write-Host "==================================================" -ForegroundColor Red

# Function to destroy a service
function Destroy-Service {
    param(
        [string]$ServiceName,
        [string]$ServicePath
    )
    
    Write-Host "Destroying $ServiceName..." -ForegroundColor Yellow
    
    if (Test-Path $ServicePath) {
        Push-Location $ServicePath
        
        if ((Test-Path "terraform.tfstate") -or (Test-Path ".terraform/terraform.tfstate")) {
            Write-Host "  - Found existing state, destroying..." -ForegroundColor Yellow
            terraform destroy -auto-approve
            Write-Host "  ✅ $ServiceName destroyed successfully" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  No state found for $ServiceName (already destroyed or never created)" -ForegroundColor Yellow
        }
        
        Pop-Location
    } else {
        Write-Host "  ⚠️  Directory $ServicePath not found" -ForegroundColor Yellow
    }
}

# Function to destroy shared infrastructure
function Destroy-Shared {
    param(
        [string]$SharedName,
        [string]$SharedPath
    )
    
    Write-Host "Destroying shared $SharedName..." -ForegroundColor Yellow
    
    if (Test-Path $SharedPath) {
        Push-Location $SharedPath
        
        if ((Test-Path "terraform.tfstate") -or (Test-Path ".terraform/terraform.tfstate")) {
            Write-Host "  - Found existing state, destroying..." -ForegroundColor Yellow
            terraform destroy -auto-approve
            Write-Host "  ✅ Shared $SharedName destroyed successfully" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  No state found for shared $SharedName" -ForegroundColor Yellow
        }
        
        Pop-Location
    } else {
        Write-Host "  ⚠️  Directory $SharedPath not found" -ForegroundColor Yellow
    }
}

# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Split-Path -Parent $ScriptDir

Write-Host "Terraform directory: $TerraformDir"
Write-Host ""

# Change to terraform directory
Set-Location $TerraformDir

# Confirmation prompt
if (-not $Force) {
    $confirmation = Read-Host "Are you sure you want to destroy ALL infrastructure? (yes/no)"
    if ($confirmation -ne "yes") {
        Write-Host "Destruction cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Destroy services (in reverse order of dependency)
Write-Host "🚀 Starting destruction process..." -ForegroundColor Red
Write-Host ""

# Destroy services
Destroy-Service "Spring Boot Service" "services/springboot"
Destroy-Service "Kafka Service" "services/kafka"
Destroy-Service "MQTT Service" "services/mqtt"

Write-Host ""

# Destroy shared infrastructure
Destroy-Shared "Networking" "shared/networking"

Write-Host ""
Write-Host "🎉 All infrastructure destroyed successfully!" -ForegroundColor Green
Write-Host "💰 Cost control: No AWS resources running" -ForegroundColor Green
Write-Host ""
Write-Host "💡 To redeploy tomorrow:" -ForegroundColor Yellow
Write-Host "  1. cd shared/networking && terraform apply"
Write-Host "  2. cd services/mqtt && terraform apply"
Write-Host "  3. Add other services as needed"
Write-Host ""
Write-Host "Good night! 🌙" -ForegroundColor Green




