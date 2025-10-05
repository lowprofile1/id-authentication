# ID Authentication Ingress Configuration

This directory contains Kubernetes ingress manifests for the MOSIP ID Authentication services.

## Files Overview

### Main Ingress Files

- **`authentication-ingress.yaml`** - Combined ingress with path-based routing
- **`authentication-ingress-tls.yaml`** - TLS-enabled version with SSL certificates

### Individual Service Ingress Files

- **`authentication-service-ingress.yaml`** - Main Authentication Service
- **`authentication-otp-service-ingress.yaml`** - OTP Service
- **`authentication-internal-service-ingress.yaml`** - Internal Service

### Deployment Scripts

- **`deploy-ingress.sh`** - Automated deployment script
- **`cleanup-ingress.sh`** - Cleanup script

## Prerequisites

1. **Nginx Ingress Controller** - Must be installed in your cluster
2. **Kubernetes Cluster** - Running and accessible
3. **kubectl** - Configured to access your cluster

## Installation

### Option 1: Using the Deployment Script (Recommended)

```bash
chmod +x deploy-ingress.sh
./deploy-ingress.sh
```

### Option 2: Manual Deployment

```bash
# Apply all ingress manifests
kubectl apply -f authentication-ingress.yaml
kubectl apply -f authentication-service-ingress.yaml
kubectl apply -f authentication-otp-service-ingress.yaml
kubectl apply -f authentication-internal-service-ingress.yaml
```

## Access URLs

### Combined Ingress (Path-based routing)

- **Main Entry Point**: `http://authentication.mosip.local`
- **Authentication Service**: `http://authentication.mosip.local/v1/auth`
- **OTP Service**: `http://authentication.mosip.local/v1/otp`
- **Internal Service**: `http://authentication.mosip.local/v1/internal`
- **Health Check**: `http://authentication.mosip.local/actuator/health`
- **Management**: `http://authentication.mosip.local/actuator`

### Individual Service Ingress (Subdomain-based routing)

- **Authentication Service**: `http://auth.mosip.local`
- **OTP Service**: `http://otp.mosip.local`
- **Internal Service**: `http://internal.mosip.local`

## DNS Configuration

### For Local Development

Add these entries to your `/etc/hosts` file:

```
<INGRESS_CONTROLLER_IP> authentication.mosip.local
<INGRESS_CONTROLLER_IP> auth.mosip.local
<INGRESS_CONTROLLER_IP> otp.mosip.local
<INGRESS_CONTROLLER_IP> internal.mosip.local
```

### For Production

Configure your DNS provider to point these domains to your ingress controller's external IP.

## TLS Configuration

The `authentication-ingress-tls.yaml` file includes TLS configuration with:

- **Host**: `authentication.mosip.example.com` (update as needed)
- **Certificate**: Managed by cert-manager
- **Issuer**: `letsencrypt-prod` (update as needed)

To use TLS:

1. Install cert-manager in your cluster
2. Create a ClusterIssuer for Let's Encrypt
3. Update the hostname in the TLS ingress file
4. Apply the TLS ingress manifest

## Service Endpoints

### Authentication Service

- **Base Path**: `/v1/auth`
- **Health Check**: `/actuator/health`
- **Management**: `/actuator`
- **Port**: 8090

### OTP Service

- **Base Path**: `/v1/otp`
- **Health Check**: `/actuator/health`
- **Management**: `/actuator`
- **Port**: 8090

### Internal Service

- **Base Path**: `/v1/internal`
- **Health Check**: `/actuator/health`
- **Management**: `/actuator`
- **Port**: 8090

## Ingress Annotations

All ingress manifests include the following nginx annotations:

- **CORS**: Enabled for cross-origin requests
- **Proxy Settings**: 10MB body size, 300s timeouts
- **SSL Redirect**: Disabled for HTTP, enabled for HTTPS
- **Rewrite Target**: Path rewriting for proper routing

## Monitoring

Check ingress status:

```bash
kubectl get ingress -n mosip-ida
kubectl describe ingress -n mosip-ida
```

Check nginx ingress controller logs:

```bash
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

## Troubleshooting

### Common Issues

1. **404 Errors**: Check if services are running and accessible
2. **502 Errors**: Check if pods are ready and healthy
3. **DNS Resolution**: Verify DNS configuration or /etc/hosts entries
4. **TLS Issues**: Check certificate status and cert-manager logs

### Debug Commands

```bash
# Check ingress status
kubectl get ingress -n mosip-ida -o wide

# Check ingress events
kubectl describe ingress -n mosip-ida

# Check nginx configuration
kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- cat /etc/nginx/nginx.conf

# Test connectivity
curl -H "Host: authentication.mosip.local" http://<INGRESS_IP>/actuator/health
```

## Customization

### Updating Hostnames

Edit the `spec.rules[].host` field in each ingress manifest to match your domain.

### Adding Authentication

Add nginx auth annotations:

```yaml
annotations:
  nginx.ingress.kubernetes.io/auth-type: basic
  nginx.ingress.kubernetes.io/auth-secret: basic-auth
  nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
```

### Rate Limiting

Add rate limiting annotations:

```yaml
annotations:
  nginx.ingress.kubernetes.io/rate-limit: "100"
  nginx.ingress.kubernetes.io/rate-limit-window: "1m"
```

## API Documentation

### Authentication Service Endpoints

- **POST** `/v1/auth/authenticate` - Authenticate user
- **POST** `/v1/auth/validate` - Validate authentication
- **GET** `/v1/auth/status` - Get authentication status

### OTP Service Endpoints

- **POST** `/v1/otp/generate` - Generate OTP
- **POST** `/v1/otp/validate` - Validate OTP
- **GET** `/v1/otp/status` - Get OTP status

### Internal Service Endpoints

- **POST** `/v1/internal/process` - Process internal requests
- **GET** `/v1/internal/status` - Get internal service status

## Security Considerations

1. **CORS**: Currently configured to allow all origins (`*`). Restrict in production.
2. **TLS**: Use HTTPS in production environments.
3. **Authentication**: Consider adding authentication middleware.
4. **Rate Limiting**: Implement rate limiting for production use.
5. **Input Validation**: Ensure all inputs are properly validated.

## Performance Tuning

### Nginx Configuration

- **Proxy Timeout**: 300 seconds (configurable)
- **Body Size**: 10MB (configurable)
- **Worker Processes**: Auto-detected by nginx

### Resource Limits

- **CPU**: 250m request, 500m limit
- **Memory**: 512Mi request, 1Gi limit

## Backup and Recovery

### Backup Ingress Configuration

```bash
kubectl get ingress -n mosip-ida -o yaml > authentication-ingress-backup.yaml
```

### Restore Ingress Configuration

```bash
kubectl apply -f authentication-ingress-backup.yaml
```
