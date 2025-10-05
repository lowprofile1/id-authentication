#!/bin/bash

# MOSIP Infrastructure Cleanup Script
# This script removes the MOSIP infrastructure and monitoring stack

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="dev"
REGION="us-east-1"
SKIP_MONITORING=false
SKIP_INFRASTRUCTURE=false
FORCE=false

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
    echo "  -e, --environment ENV    Environment to cleanup (dev, qa, prod) [default: dev]"
    echo "  -r, --region REGION      AWS region [default: us-east-1]"
    echo "  --skip-infrastructure    Skip infrastructure cleanup"
    echo "  --skip-monitoring        Skip monitoring stack cleanup"
    echo "  --force                 Force cleanup without confirmation"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --environment dev"
    echo "  $0 --environment prod --force"
    echo "  $0 --skip-infrastructure --skip-monitoring"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        --skip-infrastructure)
            SKIP_INFRASTRUCTURE=true
            shift
            ;;
        --skip-monitoring)
            SKIP_MONITORING=true
            shift
            ;;
        --force)
            FORCE=true
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

print_status "Starting MOSIP Infrastructure cleanup..."
print_status "Environment: $ENVIRONMENT"
print_status "Region: $REGION"

# Confirmation prompt
if [ "$FORCE" = false ]; then
    print_warning "This will destroy all infrastructure and monitoring resources for environment: $ENVIRONMENT"
    read -p "Are you sure you want to continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_status "Cleanup cancelled"
        exit 0
    fi
fi

# Cleanup Monitoring Stack
if [ "$SKIP_MONITORING" = false ]; then
    print_status "Cleaning up monitoring stack..."
    
    # Remove monitoring resources
    kubectl delete -f monitoring/prometheus/ --ignore-not-found=true
    kubectl delete -f monitoring/grafana/ --ignore-not-found=true
    kubectl delete -f monitoring/elasticsearch/ --ignore-not-found=true
    kubectl delete -f monitoring/kibana/ --ignore-not-found=true
    kubectl delete -f monitoring/fluentd/ --ignore-not-found=true
    
    # Remove monitoring namespace
    kubectl delete namespace monitoring --ignore-not-found=true
    
    print_success "Monitoring stack cleanup completed"
else
    print_warning "Skipping monitoring stack cleanup"
fi

# Cleanup Infrastructure
if [ "$SKIP_INFRASTRUCTURE" = false ]; then
    print_status "Cleaning up infrastructure for environment: $ENVIRONMENT"
    
    cd infrastructure/environments/$ENVIRONMENT
    
    # Destroy Terraform resources
    print_status "Destroying Terraform resources..."
    terraform destroy -auto-approve
    
    print_success "Infrastructure cleanup completed"
else
    print_warning "Skipping infrastructure cleanup"
fi

# Display cleanup status
print_status "Cleanup Status:"
echo ""
echo "=== Monitoring Stack ==="
kubectl get pods -n monitoring 2>/dev/null || echo "No monitoring pods found"

echo ""
echo "=== Infrastructure ==="
if [ "$SKIP_INFRASTRUCTURE" = false ]; then
    terraform show 2>/dev/null || echo "No infrastructure resources found"
fi

echo ""
print_success "MOSIP Infrastructure cleanup completed successfully!"
echo ""
echo "=== Cleanup Summary ==="
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo ""
echo "=== Verification Commands ==="
echo "Check remaining resources: kubectl get all --all-namespaces"
echo "Check AWS resources: aws ec2 describe-instances --region $REGION"
echo "Check EKS clusters: aws eks list-clusters --region $REGION"
