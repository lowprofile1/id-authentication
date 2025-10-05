#!/bin/bash

# Deploy All MOSIP Ingress Manifests
# This script deploys ingress configurations for both ID Authentication and Registration Processor services

echo "🚀 Deploying All MOSIP Ingress Manifests..."

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

# Create namespaces if they don't exist
echo "📦 Ensuring namespaces exist..."
kubectl create namespace mosip-ida --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace mosip-registration --dry-run=client -o yaml | kubectl apply -f -

# Deploy ID Authentication Ingress
echo "🔐 Deploying ID Authentication Ingress..."
kubectl apply -f authentication-ingress.yaml
kubectl apply -f authentication-service-ingress.yaml
kubectl apply -f authentication-otp-service-ingress.yaml
kubectl apply -f authentication-internal-service-ingress.yaml

# Deploy Registration Processor Ingress
echo "📝 Deploying Registration Processor Ingress..."
kubectl apply -f ../mosip-registration/k8s/registration-processor-ingress.yaml
kubectl apply -f ../mosip-registration/k8s/registration-processor-workflow-manager-ingress.yaml
kubectl apply -f ../mosip-registration/k8s/registration-processor-stage-group-1-ingress.yaml
kubectl apply -f ../mosip-registration/k8s/registration-processor-registration-status-ingress.yaml
kubectl apply -f ../mosip-registration/k8s/registration-processor-notification-ingress.yaml
kubectl apply -f ../mosip-registration/k8s/registration-processor-landing-zone-ingress.yaml

# Wait for ingress to be ready
echo "⏳ Waiting for ingress to be ready..."
kubectl wait --for=condition=ready ingress --all -n mosip-ida --timeout=60s || echo "⚠️  Some ID Authentication ingresses may not be ready yet"
kubectl wait --for=condition=ready ingress --all -n mosip-registration --timeout=60s || echo "⚠️  Some Registration Processor ingresses may not be ready yet"

# Display ingress status
echo "📊 ID Authentication Ingress Status:"
kubectl get ingress -n mosip-ida

echo ""
echo "📊 Registration Processor Ingress Status:"
kubectl get ingress -n mosip-registration

echo ""
echo "✅ All ingress deployment completed!"
echo ""
echo "🌐 ID Authentication Access URLs:"
echo "  - Main: http://authentication.mosip.local"
echo "  - Authentication Service: http://auth.mosip.local"
echo "  - OTP Service: http://otp.mosip.local"
echo "  - Internal Service: http://internal.mosip.local"
echo ""
echo "🌐 Registration Processor Access URLs:"
echo "  - Main: http://registration.mosip.local"
echo "  - Workflow Manager: http://workflow-manager.registration.mosip.local"
echo "  - Stage Group 1: http://stage-group-1.registration.mosip.local"
echo "  - Registration Status: http://registration-status.registration.mosip.local"
echo "  - Notification: http://notification.registration.mosip.local"
echo "  - Landing Zone: http://landing-zone.registration.mosip.local"
echo ""
echo "📝 Note: Make sure nginx ingress controller is installed and running"
echo "📝 Note: Update your DNS or /etc/hosts file to point these domains to your ingress controller IP"
