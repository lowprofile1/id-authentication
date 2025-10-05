#!/bin/bash

# Deploy ID Authentication Ingress Manifests
# This script deploys all ingress configurations for the ID authentication services

echo "🚀 Deploying ID Authentication Ingress Manifests..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we can connect to the cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    exit 1
fi

# Create namespace if it doesn't exist
echo "📦 Ensuring namespace exists..."
kubectl create namespace mosip-ida --dry-run=client -o yaml | kubectl apply -f -

# Deploy main combined ingress
echo "🌐 Deploying main combined ingress..."
kubectl apply -f authentication-ingress.yaml

# Deploy individual service ingresses
echo "🔧 Deploying individual service ingresses..."

echo "  - Authentication Service Ingress"
kubectl apply -f authentication-service-ingress.yaml

echo "  - OTP Service Ingress"
kubectl apply -f authentication-otp-service-ingress.yaml

echo "  - Internal Service Ingress"
kubectl apply -f authentication-internal-service-ingress.yaml

# Wait for ingress to be ready
echo "⏳ Waiting for ingress to be ready..."
kubectl wait --for=condition=ready ingress --all -n mosip-ida --timeout=60s || echo "⚠️  Some ingresses may not be ready yet"

# Display ingress status
echo "📊 Ingress Status:"
kubectl get ingress -n mosip-ida

echo ""
echo "✅ Ingress deployment completed!"
echo ""
echo "🌐 Access URLs (update your /etc/hosts or DNS):"
echo "  - Main: http://authentication.mosip.local"
echo "  - Authentication Service: http://auth.mosip.local"
echo "  - OTP Service: http://otp.mosip.local"
echo "  - Internal Service: http://internal.mosip.local"
echo ""
echo "📝 Note: Make sure nginx ingress controller is installed and running"
echo "📝 Note: Update your DNS or /etc/hosts file to point these domains to your ingress controller IP"
