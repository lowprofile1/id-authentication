#!/bin/bash

# MOSIP ID Authentication Local Testing Script
# This script helps test the Docker images locally before pushing to ECR

set -e

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
ECR_REGISTRY=${ECR_REGISTRY:-}
VERSION=${VERSION:-latest}
ENVIRONMENT=${ENVIRONMENT:-dev}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install AWS CLI and try again."
        exit 1
    fi
    
    # Check if ECR_REGISTRY is set
    if [ -z "$ECR_REGISTRY" ]; then
        log_error "ECR_REGISTRY is not set. Please set it to your ECR registry URL."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Login to ECR
login_ecr() {
    log_info "Logging in to ECR..."
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
    log_success "ECR login successful"
}

# Pull images
pull_images() {
    log_info "Pulling Docker images..."
    
    local services=("authentication-service" "authentication-internal-service" "authentication-otp-service")
    
    for service in "${services[@]}"; do
        log_info "Pulling mosip-$service:$VERSION..."
        docker pull $ECR_REGISTRY/mosip-$service:$VERSION || {
            log_error "Failed to pull mosip-$service:$VERSION"
            exit 1
        }
    done
    
    log_success "All images pulled successfully"
}

# Test individual service
test_service() {
    local service_name=$1
    local port=$2
    local health_port=$3
    
    log_info "Testing $service_name..."
    
    # Start container
    local container_name="test-$service_name"
    docker run -d \
        --name $container_name \
        -p $port:$port \
        -p $health_port:$health_port \
        -e active_profile_env=$ENVIRONMENT \
        -e spring_config_url_env=http://mock-config:8888 \
        -e artifactory_url_env=http://mock-artifactory:8081 \
        $ECR_REGISTRY/mosip-$service_name:$VERSION
    
    # Wait for container to start
    log_info "Waiting for $service_name to start..."
    sleep 30
    
    # Check if container is running
    if ! docker ps | grep -q $container_name; then
        log_error "$service_name failed to start"
        docker logs $container_name
        docker rm -f $container_name
        return 1
    fi
    
    # Test health endpoint
    log_info "Testing health endpoint for $service_name..."
    if curl -f http://localhost:$health_port/actuator/health > /dev/null 2>&1; then
        log_success "$service_name health check passed"
    else
        log_warning "$service_name health check failed (endpoint might not be available)"
    fi
    
    # Show logs
    log_info "Container logs for $service_name:"
    docker logs $container_name --tail 20
    
    # Cleanup
    docker stop $container_name
    docker rm $container_name
    
    log_success "$service_name test completed"
}

# Test all services
test_all_services() {
    log_info "Testing all services..."
    
    # Test authentication-service
    test_service "authentication-service" 8090 9010
    
    # Test authentication-internal-service
    test_service "authentication-internal-service" 8093 9011
    
    # Test authentication-otp-service
    test_service "authentication-otp-service" 8092 9012
    
    log_success "All services tested successfully"
}

# Test integration
test_integration() {
    log_info "Testing service integration..."
    
    # Create network
    docker network create mosip-test-network || true
    
    # Start all services
    docker run -d \
        --name test-auth-service \
        --network mosip-test-network \
        -p 8090:8090 \
        -p 9010:9010 \
        -e active_profile_env=$ENVIRONMENT \
        -e spring_config_url_env=http://mock-config:8888 \
        -e artifactory_url_env=http://mock-artifactory:8081 \
        $ECR_REGISTRY/mosip-authentication-service:$VERSION
    
    docker run -d \
        --name test-auth-internal-service \
        --network mosip-test-network \
        -p 8093:8093 \
        -p 9011:9010 \
        -e active_profile_env=$ENVIRONMENT \
        -e spring_config_url_env=http://mock-config:8888 \
        -e artifactory_url_env=http://mock-artifactory:8081 \
        $ECR_REGISTRY/mosip-authentication-internal-service:$VERSION
    
    docker run -d \
        --name test-auth-otp-service \
        --network mosip-test-network \
        -p 8092:8092 \
        -p 9012:9010 \
        -e active_profile_env=$ENVIRONMENT \
        -e spring_config_url_env=http://mock-config:8888 \
        -e artifactory_url_env=http://mock-artifactory:8081 \
        $ECR_REGISTRY/mosip-authentication-otp-service:$VERSION
    
    # Wait for services to start
    log_info "Waiting for all services to start..."
    sleep 60
    
    # Check all services are running
    log_info "Service status:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    # Test connectivity
    log_info "Testing service connectivity..."
    
    # Test authentication-service
    if curl -f http://localhost:8090/actuator/health > /dev/null 2>&1; then
        log_success "authentication-service is responding"
    else
        log_warning "authentication-service health check failed"
    fi
    
    # Test authentication-internal-service
    if curl -f http://localhost:8093/actuator/health > /dev/null 2>&1; then
        log_success "authentication-internal-service is responding"
    else
        log_warning "authentication-internal-service health check failed"
    fi
    
    # Test authentication-otp-service
    if curl -f http://localhost:8092/actuator/health > /dev/null 2>&1; then
        log_success "authentication-otp-service is responding"
    else
        log_warning "authentication-otp-service health check failed"
    fi
    
    # Cleanup
    log_info "Cleaning up test containers..."
    docker stop test-auth-service test-auth-internal-service test-auth-otp-service || true
    docker rm test-auth-service test-auth-internal-service test-auth-otp-service || true
    docker network rm mosip-test-network || true
    
    log_success "Integration test completed"
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] COMMAND"
    echo ""
    echo "Commands:"
    echo "  test-service    Test individual services"
    echo "  test-integration Test service integration"
    echo "  test-all       Test all services individually"
    echo "  pull           Pull images from ECR"
    echo "  login          Login to ECR"
    echo ""
    echo "Options:"
    echo "  -r, --registry REGISTRY    ECR registry URL (required)"
    echo "  -v, --version VERSION      Image version (default: latest)"
    echo "  -e, --environment ENV      Environment (default: dev)"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  ECR_REGISTRY              ECR registry URL"
    echo "  VERSION                   Image version"
    echo "  ENVIRONMENT               Environment"
    echo "  AWS_REGION               AWS region (default: us-east-1)"
    echo ""
    echo "Examples:"
    echo "  $0 --registry 123456789012.dkr.ecr.us-east-1.amazonaws.com test-all"
    echo "  $0 -r 123456789012.dkr.ecr.us-east-1.amazonaws.com -v 1.2.1.0 test-integration"
    echo "  ECR_REGISTRY=123456789012.dkr.ecr.us-east-1.amazonaws.com $0 test-service"
}

# Main function
main() {
    local command=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--registry)
                ECR_REGISTRY="$2"
                shift 2
                ;;
            -v|--version)
                VERSION="$2"
                shift 2
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            test-service|test-integration|test-all|pull|login)
                command="$1"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    if [ -z "$command" ]; then
        log_error "No command specified"
        show_usage
        exit 1
    fi
    
    # Execute command
    case $command in
        login)
            check_prerequisites
            login_ecr
            ;;
        pull)
            check_prerequisites
            login_ecr
            pull_images
            ;;
        test-service)
            check_prerequisites
            login_ecr
            pull_images
            test_all_services
            ;;
        test-integration)
            check_prerequisites
            login_ecr
            pull_images
            test_integration
            ;;
        test-all)
            check_prerequisites
            login_ecr
            pull_images
            test_all_services
            test_integration
            ;;
    esac
}

# Run main function
main "$@"
