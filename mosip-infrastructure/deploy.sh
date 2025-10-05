#!/bin/bash

# MOSIP Infrastructure Deployment Script
# This script deploys the complete MOSIP infrastructure and monitoring stack

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
    echo "  -e, --environment ENV    Environment to deploy (dev, qa, prod) [default: dev]"
    echo "  -r, --region REGION      AWS region [default: us-east-1]"
    echo "  --skip-infrastructure    Skip infrastructure deployment"
    echo "  --skip-monitoring        Skip monitoring stack deployment"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --environment dev"
    echo "  $0 --environment prod --region us-west-2"
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

print_status "Starting MOSIP Infrastructure deployment..."
print_status "Environment: $ENVIRONMENT"
print_status "Region: $REGION"

# Check prerequisites
print_status "Checking prerequisites..."

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed or not in PATH"
    exit 1
fi

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

# Deploy Infrastructure
if [ "$SKIP_INFRASTRUCTURE" = false ]; then
    print_status "Deploying infrastructure for environment: $ENVIRONMENT"
    
    cd infrastructure/environments/$ENVIRONMENT
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    
    # Apply deployment
    print_status "Applying Terraform deployment..."
    terraform apply tfplan
    
    # Get cluster name
    CLUSTER_NAME=$(terraform output -raw cluster_name)
    
    # Configure kubectl
    print_status "Configuring kubectl for EKS cluster..."
    aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
    
    print_success "Infrastructure deployment completed"
else
    print_warning "Skipping infrastructure deployment"
fi

# Deploy Monitoring Stack
if [ "$SKIP_MONITORING" = false ]; then
    print_status "Deploying monitoring stack..."
    
    cd ../../monitoring
    
    # Deploy Prometheus
    print_status "Deploying Prometheus..."
    kubectl apply -f prometheus/
    
    # Deploy Grafana
    print_status "Deploying Grafana..."
    kubectl apply -f grafana/
    
    # Deploy Elasticsearch
    print_status "Deploying Elasticsearch..."
    kubectl apply -f elasticsearch/
    
    # Deploy Kibana
    print_status "Deploying Kibana..."
    kubectl apply -f kibana/
    
    # Deploy Fluentd
    print_status "Deploying Fluentd..."
    kubectl apply -f fluentd/
    
    # Wait for monitoring stack to be ready
    print_status "Waiting for monitoring stack to be ready..."
    kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=300s || echo "Prometheus not ready yet"
    kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=300s || echo "Grafana not ready yet"
    
    print_success "Monitoring stack deployment completed"
else
    print_warning "Skipping monitoring stack deployment"
fi

# Display deployment status
print_status "Deployment Status:"
echo ""
echo "=== Infrastructure ==="
if [ "$SKIP_INFRASTRUCTURE" = false ]; then
    terraform output
fi

echo ""
echo "=== Monitoring Stack ==="
kubectl get pods -n monitoring

echo ""
echo "=== Services ==="
kubectl get services -n monitoring

echo ""
print_success "MOSIP Infrastructure deployment completed successfully!"
echo ""
echo "=== Access Information ==="
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo ""
echo "=== Management Commands ==="
echo "View infrastructure: terraform show"
echo "View monitoring pods: kubectl get pods -n monitoring"
echo "View monitoring services: kubectl get services -n monitoring"
echo "Port forward Grafana: kubectl port-forward service/grafana 3000:3000 -n monitoring"
echo "Port forward Prometheus: kubectl port-forward service/prometheus 9090:9090 -n monitoring"
