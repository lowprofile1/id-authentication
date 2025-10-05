# MOSIP ID Authentication Kubernetes Deployment Script
# This script deploys the MOSIP ID Authentication services to Kubernetes

param(
    [string]$Environment = "dev",
    [string]$Version = "latest",
    [string]$Namespace = "mosip-ida",
    [string]$ClusterName = "mosip-ida-dev-cluster",
    [string]$AwsRegion = "us-east-1",
    [switch]$SkipTests,
    [switch]$Help
)

# Function to show usage
function Show-Usage {
    Write-Host "Usage: .\deploy.ps1 [OPTIONS]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Environment ENV     Environment to deploy to (dev, qa, prod) [default: dev]"
    Write-Host "  -Version VERSION     Version tag for the deployment [default: latest]"
    Write-Host "  -Namespace NS        Kubernetes namespace [default: mosip-ida]"
    Write-Host "  -ClusterName CLUSTER EKS cluster name [default: mosip-ida-dev-cluster]"
    Write-Host "  -AwsRegion REGION    AWS region [default: us-east-1]"
    Write-Host "  -SkipTests           Skip running tests before deployment"
    Write-Host "  -Help                Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\deploy.ps1 -Environment dev -Version v1.2.1"
    Write-Host "  .\deploy.ps1 -Environment prod -Version latest"
    Write-Host "  .\deploy.ps1 -SkipTests"
}

# Show help if requested
if ($Help) {
    Show-Usage
    exit 0
}

# Validate environment
if ($Environment -notmatch "^(dev|qa|prod)$") {
    Write-Host "[ERROR] Invalid environment: $Environment. Must be one of: dev, qa, prod" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Starting MOSIP ID Authentication deployment..." -ForegroundColor Blue
Write-Host "[INFO] Environment: $Environment" -ForegroundColor Blue
Write-Host "[INFO] Version: $Version" -ForegroundColor Blue
Write-Host "[INFO] Namespace: $Namespace" -ForegroundColor Blue
Write-Host "[INFO] Cluster: $ClusterName" -ForegroundColor Blue
Write-Host "[INFO] Region: $AwsRegion" -ForegroundColor Blue

# Check prerequisites
Write-Host "[INFO] Checking prerequisites..." -ForegroundColor Blue

# Check if kubectl is installed
try {
    kubectl version --client | Out-Null
    Write-Host "[SUCCESS] kubectl is available" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] kubectl is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if aws CLI is installed
try {
    aws --version | Out-Null
    Write-Host "[SUCCESS] AWS CLI is available" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] AWS CLI is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check AWS credentials
try {
    aws sts get-caller-identity | Out-Null
    Write-Host "[SUCCESS] AWS credentials are valid" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] AWS credentials not configured or invalid" -ForegroundColor Red
    exit 1
}

Write-Host "[SUCCESS] Prerequisites check passed" -ForegroundColor Green

# Configure kubectl for EKS
Write-Host "[INFO] Configuring kubectl for EKS cluster..." -ForegroundColor Blue
aws eks update-kubeconfig --region $AwsRegion --name $ClusterName

# Verify cluster connection
Write-Host "[INFO] Verifying cluster connection..." -ForegroundColor Blue
try {
    kubectl get nodes | Out-Null
    Write-Host "[SUCCESS] Successfully connected to EKS cluster" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to connect to EKS cluster: $ClusterName" -ForegroundColor Red
    exit 1
}

# Create namespace if it doesn't exist
Write-Host "[INFO] Creating namespace: $Namespace" -ForegroundColor Blue
kubectl apply -f namespace.yaml

# Update manifests with environment-specific values
Write-Host "[INFO] Updating manifests for environment: $Environment" -ForegroundColor Blue

# Update database host in configmap
$DbHost = switch ($Environment) {
    "dev" { "mosip-ida-dev-db.ckbisyiait0e.us-east-1.rds.amazonaws.com" }
    "qa" { "mosip-ida-qa-db.ckbisyiait0e.us-east-1.rds.amazonaws.com" }
    "prod" { "mosip-ida-prod-db.ckbisyiait0e.us-east-1.rds.amazonaws.com" }
}

# Update image tags
Write-Host "[INFO] Updating image tags to version: $Version" -ForegroundColor Blue
Get-ChildItem -Path . -Name "*-deployment.yaml" | ForEach-Object {
    (Get-Content $_) -replace ":latest", ":$Version" | Set-Content $_
}

# Update configmap with environment-specific database host
(Get-Content configmap.yaml) -replace "DB_HOST: .*", "DB_HOST: $DbHost" | Set-Content configmap.yaml

Write-Host "[SUCCESS] Manifests updated successfully" -ForegroundColor Green

# Deploy ConfigMap and Secrets
Write-Host "[INFO] Deploying ConfigMap and Secrets..." -ForegroundColor Blue
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

# Deploy services
Write-Host "[INFO] Deploying Authentication Service..." -ForegroundColor Blue
kubectl apply -f authentication-service-deployment.yaml

Write-Host "[INFO] Deploying Authentication Internal Service..." -ForegroundColor Blue
kubectl apply -f authentication-internal-service-deployment.yaml

Write-Host "[INFO] Deploying Authentication OTP Service..." -ForegroundColor Blue
kubectl apply -f authentication-otp-service-deployment.yaml

Write-Host "[INFO] Deploying Ingress..." -ForegroundColor Blue
kubectl apply -f ingress.yaml

# Wait for deployments to be ready
Write-Host "[INFO] Waiting for deployments to be ready..." -ForegroundColor Blue
kubectl wait --for=condition=available --timeout=300s deployment/authentication-service -n $Namespace
kubectl wait --for=condition=available --timeout=300s deployment/authentication-internal-service -n $Namespace
kubectl wait --for=condition=available --timeout=300s deployment/authentication-otp-service -n $Namespace

Write-Host "[SUCCESS] All deployments are ready!" -ForegroundColor Green

# Display deployment status
Write-Host "[INFO] Deployment Status:" -ForegroundColor Blue
Write-Host ""
Write-Host "=== Pods ===" -ForegroundColor Yellow
kubectl get pods -n $Namespace
Write-Host ""
Write-Host "=== Services ===" -ForegroundColor Yellow
kubectl get services -n $Namespace
Write-Host ""
Write-Host "=== Ingress ===" -ForegroundColor Yellow
kubectl get ingress -n $Namespace

# Get ALB URL
try {
    $AlbUrl = kubectl get ingress mosip-ida-ingress -n $Namespace -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
    if (-not $AlbUrl) { $AlbUrl = "Pending..." }
} catch {
    $AlbUrl = "Pending..."
}

Write-Host ""
Write-Host "[SUCCESS] Deployment completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "=== Access Information ===" -ForegroundColor Yellow
Write-Host "ALB URL: $AlbUrl"
Write-Host "Environment: $Environment"
Write-Host "Version: $Version"
Write-Host "Namespace: $Namespace"
Write-Host ""
Write-Host "=== Management Commands ===" -ForegroundColor Yellow
Write-Host "View pods: kubectl get pods -n $Namespace"
Write-Host "View services: kubectl get services -n $Namespace"
Write-Host "View logs: kubectl logs -f deployment/authentication-service -n $Namespace"
Write-Host "Port forward: kubectl port-forward service/authentication-service 8090:8090 -n $Namespace"
