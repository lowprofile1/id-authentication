#!/bin/bash

# MOSIP ID Authentication Kubernetes Deployment Script
# This script deploys the MOSIP ID Authentication services to Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="dev"
VERSION="latest"
NAMESPACE="mosip-ida"
CLUSTER_NAME="mosip-ida-dev-cluster"
AWS_REGION="us-east-1"
SKIP_TESTS=false

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -e, --environment ENV    Environment to deploy to (dev, qa, prod) [default: dev]"
    echo "  -v, --version VERSION    Version tag for the deployment [default: latest]"
    echo "  -n, --namespace NS       Kubernetes namespace [default: mosip-ida]"
    echo "  -c, --cluster CLUSTER    EKS cluster name [default: mosip-ida-dev-cluster]"
    echo "  -r, --region REGION      AWS region [default: us-east-1]"
    echo "  --skip-tests            Skip running tests before deployment"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --environment dev --version v1.2.1"
    echo "  $0 --environment prod --version latest"
    echo "  $0 --skip-tests"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -c|--cluster)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|qa|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Must be one of: dev, qa, prod"
    exit 1
fi

print_status "Starting MOSIP ID Authentication deployment..."
print_status "Environment: $ENVIRONMENT"
print_status "Version: $VERSION"
print_status "Namespace: $NAMESPACE"
print_status "Cluster: $CLUSTER_NAME"
print_status "Region: $AWS_REGION"

# Check prerequisites
print_status "Checking prerequisites..."

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if aws CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed or not in PATH"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured or invalid"
    exit 1
fi

print_success "Prerequisites check passed"

# Configure kubectl for EKS
print_status "Configuring kubectl for EKS cluster..."
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Verify cluster connection
print_status "Verifying cluster connection..."
if ! kubectl get nodes &> /dev/null; then
    print_error "Failed to connect to EKS cluster: $CLUSTER_NAME"
    exit 1
fi

print_success "Successfully connected to EKS cluster"

# Create namespace if it doesn't exist
print_status "Creating namespace: $NAMESPACE"
kubectl apply -f namespace.yaml

# Update manifests with environment-specific values
print_status "Updating manifests for environment: $ENVIRONMENT"

# Update database host in configmap
if [[ "$ENVIRONMENT" == "dev" ]]; then
    DB_HOST="mosip-ida-dev-db.ckbisyiait0e.us-east-1.rds.amazonaws.com"
elif [[ "$ENVIRONMENT" == "qa" ]]; then
    DB_HOST="mosip-ida-qa-db.ckbisyiait0e.us-east-1.rds.amazonaws.com"
elif [[ "$ENVIRONMENT" == "prod" ]]; then
    DB_HOST="mosip-ida-prod-db.ckbisyiait0e.us-east-1.rds.amazonaws.com"
fi

# Update image tags
print_status "Updating image tags to version: $VERSION"
find . -name "*-deployment.yaml" -exec sed -i "s|:latest|:$VERSION|g" {} \;

# Update configmap with environment-specific database host
sed -i "s|DB_HOST: .*|DB_HOST: $DB_HOST|g" configmap.yaml

print_success "Manifests updated successfully"

# Deploy ConfigMap and Secrets
print_status "Deploying ConfigMap and Secrets..."
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

# Deploy services
print_status "Deploying Authentication Service..."
kubectl apply -f authentication-service-deployment.yaml

print_status "Deploying Authentication Internal Service..."
kubectl apply -f authentication-internal-service-deployment.yaml

print_status "Deploying Authentication OTP Service..."
kubectl apply -f authentication-otp-service-deployment.yaml

print_status "Deploying Ingress..."
kubectl apply -f ingress.yaml

# Wait for deployments to be ready
print_status "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/authentication-service -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/authentication-internal-service -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/authentication-otp-service -n $NAMESPACE

print_success "All deployments are ready!"

# Display deployment status
print_status "Deployment Status:"
echo ""
echo "=== Pods ==="
kubectl get pods -n $NAMESPACE
echo ""
echo "=== Services ==="
kubectl get services -n $NAMESPACE
echo ""
echo "=== Ingress ==="
kubectl get ingress -n $NAMESPACE

# Get ALB URL
ALB_URL=$(kubectl get ingress mosip-ida-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending...")

echo ""
print_success "Deployment completed successfully!"
echo ""
echo "=== Access Information ==="
echo "ALB URL: $ALB_URL"
echo "Environment: $ENVIRONMENT"
echo "Version: $VERSION"
echo "Namespace: $NAMESPACE"
echo ""
echo "=== Management Commands ==="
echo "View pods: kubectl get pods -n $NAMESPACE"
echo "View services: kubectl get services -n $NAMESPACE"
echo "View logs: kubectl logs -f deployment/authentication-service -n $NAMESPACE"
echo "Port forward: kubectl port-forward service/authentication-service 8090:8090 -n $NAMESPACE"
