# MOSIP ID Authentication Local Testing Script (PowerShell)
# This script helps test the Docker images locally before pushing to ECR

param(
    [Parameter(Mandatory=$false)]
    [string]$Registry,
    
    [Parameter(Mandatory=$false)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [string]$AwsRegion,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("test-service", "test-integration", "test-all", "pull", "login", "help")]
    [string]$Command
)

# Set defaults if not provided
if (-not $Registry) { $Registry = $env:ECR_REGISTRY }
if (-not $Version) { $Version = if ($env:VERSION) { $env:VERSION } else { "latest" } }
if (-not $Environment) { $Environment = if ($env:ENVIRONMENT) { $env:ENVIRONMENT } else { "dev" } }
if (-not $AwsRegion) { $AwsRegion = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-1" } }

# Configuration
$Services = @(
    @{ Name = "authentication-service"; Port = 8090; HealthPort = 9010 }
    @{ Name = "authentication-internal-service"; Port = 8093; HealthPort = 9010 }
    @{ Name = "authentication-otp-service"; Port = 8092; HealthPort = 9010 }
)

# Functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check if Docker is running
    try {
        docker info | Out-Null
    }
    catch {
        Write-Error "Docker is not running. Please start Docker and try again."
        exit 1
    }
    
    # Check if AWS CLI is installed
    try {
        aws --version | Out-Null
    }
    catch {
        Write-Error "AWS CLI is not installed. Please install AWS CLI and try again."
        exit 1
    }
    
    # Check if Registry is set
    if ([string]::IsNullOrEmpty($Registry)) {
        Write-Error "ECR_REGISTRY is not set. Please set it to your ECR registry URL."
        exit 1
    }
    
    Write-Success "Prerequisites check passed"
}

function Invoke-EcrLogin {
    Write-Info "Logging in to ECR..."
    $loginCommand = "aws ecr get-login-password --region $AwsRegion | docker login --username AWS --password-stdin $Registry"
    Invoke-Expression $loginCommand
    Write-Success "ECR login successful"
}

function Invoke-PullImages {
    Write-Info "Pulling Docker images..."
    
    foreach ($service in $Services) {
        $imageName = "$Registry/mosip-$($service.Name):$Version"
        Write-Info "Pulling $imageName..."
        
        try {
            docker pull $imageName
            Write-Success "Successfully pulled $imageName"
        }
        catch {
            Write-Error "Failed to pull $imageName"
            exit 1
        }
    }
    
    Write-Success "All images pulled successfully"
}

function Test-Service {
    param(
        [string]$ServiceName,
        [int]$Port,
        [int]$HealthPort
    )
    
    Write-Info "Testing $ServiceName..."
    
    $containerName = "test-$ServiceName"
    $imageName = "$Registry/mosip-$ServiceName`:$Version"
    
    try {
        # Start container
        Write-Info "Starting container for $ServiceName..."
        docker run -d `
            --name $containerName `
            -p "$Port`:$Port" `
            -p "$HealthPort`:$HealthPort" `
            -e "active_profile_env=$Environment" `
            -e "spring_config_url_env=http://mock-config:8888" `
            -e "artifactory_url_env=http://mock-artifactory:8081" `
            $imageName
        
        # Wait for container to start
        Write-Info "Waiting for $ServiceName to start..."
        Start-Sleep -Seconds 30
        
        # Check if container is running
        $runningContainers = docker ps --filter "name=$containerName" --format "{{.Names}}"
        if ($runningContainers -notcontains $containerName) {
            Write-Error "$ServiceName failed to start"
            docker logs $containerName
            docker rm -f $containerName
            return $false
        }
        
        # Test health endpoint
        Write-Info "Testing health endpoint for $ServiceName..."
        try {
            $healthUrl = "http://localhost:$HealthPort/actuator/health"
            $response = Invoke-WebRequest -Uri $healthUrl -TimeoutSec 10 -ErrorAction Stop
            Write-Success "$ServiceName health check passed"
        }
        catch {
            Write-Warning "$ServiceName health check failed (endpoint might not be available)"
        }
        
        # Show logs
        Write-Info "Container logs for ${ServiceName}:"
        docker logs $containerName --tail 20
        
        # Cleanup
        docker stop $containerName
        docker rm $containerName
        
        Write-Success "$ServiceName test completed"
        return $true
    }
    catch {
        Write-Error "Error testing $ServiceName`: $_"
        # Cleanup on error
        docker stop $containerName -ErrorAction SilentlyContinue
        docker rm $containerName -ErrorAction SilentlyContinue
        return $false
    }
}

function Test-AllServices {
    Write-Info "Testing all services..."
    
    $allPassed = $true
    foreach ($service in $Services) {
        $result = Test-Service -ServiceName $service.Name -Port $service.Port -HealthPort $service.HealthPort
        if (-not $result) {
            $allPassed = $false
        }
    }
    
    if ($allPassed) {
        Write-Success "All services tested successfully"
    } else {
        Write-Error "Some services failed testing"
        exit 1
    }
}

function Test-Integration {
    Write-Info "Testing service integration..."
    
    try {
        # Create network
        docker network create mosip-test-network -ErrorAction SilentlyContinue
        
        # Start all services
        Write-Info "Starting all services for integration testing..."
        
        docker run -d `
            --name test-auth-service `
            --network mosip-test-network `
            -p "8090:8090" `
            -p "9010:9010" `
            -e "active_profile_env=$Environment" `
            -e "spring_config_url_env=http://mock-config:8888" `
            -e "artifactory_url_env=http://mock-artifactory:8081" `
            "$Registry/mosip-authentication-service`:$Version"
        
        docker run -d `
            --name test-auth-internal-service `
            --network mosip-test-network `
            -p "8093:8093" `
            -p "9011:9010" `
            -e "active_profile_env=$Environment" `
            -e "spring_config_url_env=http://mock-config:8888" `
            -e "artifactory_url_env=http://mock-artifactory:8081" `
            "$Registry/mosip-authentication-internal-service`:$Version"
        
        docker run -d `
            --name test-auth-otp-service `
            --network mosip-test-network `
            -p "8092:8092" `
            -p "9012:9010" `
            -e "active_profile_env=$Environment" `
            -e "spring_config_url_env=http://mock-config:8888" `
            -e "artifactory_url_env=http://mock-artifactory:8081" `
            "$Registry/mosip-authentication-otp-service`:$Version"
        
        # Wait for services to start
        Write-Info "Waiting for all services to start..."
        Start-Sleep -Seconds 60
        
        # Check all services are running
        Write-Info "Service status:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        # Test connectivity
        Write-Info "Testing service connectivity..."
        
        # Test authentication-service
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8090/actuator/health" -TimeoutSec 10 -ErrorAction Stop
            Write-Success "authentication-service is responding"
        }
        catch {
            Write-Warning "authentication-service health check failed"
        }
        
        # Test authentication-internal-service
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8093/actuator/health" -TimeoutSec 10 -ErrorAction Stop
            Write-Success "authentication-internal-service is responding"
        }
        catch {
            Write-Warning "authentication-internal-service health check failed"
        }
        
        # Test authentication-otp-service
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8092/actuator/health" -TimeoutSec 10 -ErrorAction Stop
            Write-Success "authentication-otp-service is responding"
        }
        catch {
            Write-Warning "authentication-otp-service health check failed"
        }
        
        Write-Success "Integration test completed"
    }
    finally {
        # Cleanup
        Write-Info "Cleaning up test containers..."
        docker stop test-auth-service test-auth-internal-service test-auth-otp-service -ErrorAction SilentlyContinue
        docker rm test-auth-service test-auth-internal-service test-auth-otp-service -ErrorAction SilentlyContinue
        docker network rm mosip-test-network -ErrorAction SilentlyContinue
    }
}

function Show-Usage {
    Write-Host "Usage: .\test-local.ps1 -Command <COMMAND> [OPTIONS]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  test-service    Test individual services"
    Write-Host "  test-integration Test service integration"
    Write-Host "  test-all       Test all services individually"
    Write-Host "  pull           Pull images from ECR"
    Write-Host "  login          Login to ECR"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Registry REGISTRY    ECR registry URL (default: `$env:ECR_REGISTRY)"
    Write-Host "  -Version VERSION      Image version (default: latest)"
    Write-Host "  -Environment ENV      Environment (default: dev)"
    Write-Host "  -AwsRegion REGION     AWS region (default: us-east-1)"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\test-local.ps1 -Registry '123456789012.dkr.ecr.us-east-1.amazonaws.com' -Command test-all"
    Write-Host "  .\test-local.ps1 -Registry '123456789012.dkr.ecr.us-east-1.amazonaws.com' -Version '1.2.1.0' -Command test-integration"
    Write-Host "  `$env:ECR_REGISTRY='123456789012.dkr.ecr.us-east-1.amazonaws.com'; .\test-local.ps1 -Command test-service"
}

# Main execution
try {
    switch ($Command) {
        "login" {
            Test-Prerequisites
            Invoke-EcrLogin
        }
        "pull" {
            Test-Prerequisites
            Invoke-EcrLogin
            Invoke-PullImages
        }
        "test-service" {
            Test-Prerequisites
            Invoke-EcrLogin
            Invoke-PullImages
            Test-AllServices
        }
        "test-integration" {
            Test-Prerequisites
            Invoke-EcrLogin
            Invoke-PullImages
            Test-Integration
        }
        "test-all" {
            Test-Prerequisites
            Invoke-EcrLogin
            Invoke-PullImages
            Test-AllServices
            Test-Integration
        }
        "help" {
            Show-Usage
        }
        default {
            Write-Error "Unknown command: $Command"
            Show-Usage
            exit 1
        }
    }
}
catch {
    Write-Error "Script execution failed: $_"
    exit 1
}
