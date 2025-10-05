# MOSIP Infrastructure Repository

This repository contains the infrastructure, monitoring, and documentation for the MOSIP ID Authentication and Registration Processor platform.

## 📁 Repository Structure

```
mosip-infrastructure/
├── infrastructure/           # Terraform infrastructure code
│   ├── environments/        # Environment-specific configurations
│   │   ├── dev/            # Development environment
│   │   ├── qa/             # QA environment
│   │   └── prod/           # Production environment
│   ├── modules/            # Reusable Terraform modules
│   │   ├── eks/            # EKS cluster module
│   │   ├── rds/            # RDS database module
│   │   ├── vpc/            # VPC module
│   │   └── state-backend/   # S3 backend module
│   └── scripts/            # Deployment scripts
├── monitoring/             # Monitoring and logging stack
│   ├── elasticsearch/      # Elasticsearch configuration
│   ├── fluentd/           # Fluentd log collection
│   ├── grafana/           # Grafana dashboards
│   ├── kibana/            # Kibana configuration
│   └── prometheus/         # Prometheus configuration
├── docs/                  # Documentation
│   └── PROJECT_ARCHITECTURE_DIAGRAM.md
└── README.md              # This file
```

## 🏗️ Infrastructure Components

### **Terraform Infrastructure**

- **VPC**: Isolated network environment with public/private subnets
- **EKS Cluster**: Managed Kubernetes service for container orchestration
- **RDS PostgreSQL**: Primary database for application data
- **ElastiCache Redis**: Caching layer for performance
- **S3 Backend**: Terraform state storage with DynamoDB locking
- **Route 53**: DNS management and routing
- **CloudFront**: Content delivery network

### **Monitoring Stack**

- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **Elasticsearch**: Log storage and search
- **Kibana**: Log visualization and analysis
- **Fluentd**: Log collection from all pods
- **Jaeger**: Distributed tracing

## 🚀 Quick Start

### **Prerequisites**

- Terraform >= 1.0
- AWS CLI configured
- kubectl configured
- Docker (for local development)

### **Deploy Infrastructure**

```bash
# Navigate to infrastructure directory
cd infrastructure/environments/dev

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Deploy infrastructure
terraform apply
```

### **Deploy Monitoring Stack**

```bash
# Navigate to monitoring directory
cd monitoring

# Deploy monitoring stack
kubectl apply -f prometheus/
kubectl apply -f grafana/
kubectl apply -f elasticsearch/
kubectl apply -f kibana/
kubectl apply -f fluentd/
```

## 📊 Architecture Overview

The complete architecture is documented in `docs/PROJECT_ARCHITECTURE_DIAGRAM.md`. This includes:

- **Infrastructure Management**: Terraform with S3 backend and DynamoDB locking
- **CI/CD Pipeline**: GitHub Actions with automated deployment
- **Kubernetes Architecture**: EKS cluster with microservices
- **Monitoring & Logging**: Comprehensive observability stack
- **Security**: Network policies, secrets management, and access control

## 🔧 Environment Management

### **Development Environment**

- **Purpose**: Development and testing
- **Resources**: Minimal resources for cost optimization
- **Access**: Developer access with limited permissions

### **QA Environment**

- **Purpose**: Quality assurance and testing
- **Resources**: Production-like configuration
- **Access**: QA team and limited developer access

### **Production Environment**

- **Purpose**: Live production system
- **Resources**: High availability and performance
- **Access**: Restricted access with audit logging

## 📈 Monitoring & Observability

### **Metrics Collection**

- **Application Metrics**: Service health, response times, error rates
- **Infrastructure Metrics**: CPU, memory, disk, network usage
- **Kubernetes Metrics**: Pod status, deployment health, resource utilization

### **Logging**

- **Application Logs**: Service-specific logs with structured format
- **System Logs**: Kubernetes and infrastructure logs
- **Audit Logs**: Security and access logs

### **Alerting**

- **Critical Alerts**: Service down, high error rates, resource exhaustion
- **Warning Alerts**: Performance degradation, capacity planning
- **Info Alerts**: Deployment status, configuration changes

## 🔒 Security

### **Network Security**

- **VPC**: Isolated network environment
- **Security Groups**: Restrictive firewall rules
- **Network Policies**: Kubernetes network segmentation
- **Private Subnets**: Database and internal services

### **Access Control**

- **IAM Roles**: Least privilege access
- **RBAC**: Kubernetes role-based access control
- **Secrets Management**: Kubernetes secrets and external vaults
- **Audit Logging**: All access and changes logged

### **Data Protection**

- **Encryption at Rest**: EBS volumes and RDS encryption
- **Encryption in Transit**: TLS/SSL for all communications
- **Backup Strategy**: Automated backups with retention policies
- **Disaster Recovery**: Multi-AZ deployment and backup procedures

## 🛠️ Maintenance

### **Regular Tasks**

- **Security Updates**: OS and application patches
- **Backup Verification**: Regular backup testing
- **Performance Tuning**: Resource optimization
- **Capacity Planning**: Growth and scaling planning

### **Monitoring Tasks**

- **Dashboard Review**: Regular monitoring dashboard review
- **Alert Tuning**: Fine-tune alerting thresholds
- **Log Analysis**: Security and performance log analysis
- **Incident Response**: Document and improve incident procedures

## 📚 Documentation

- **Architecture Diagram**: Complete system architecture in `docs/`
- **Deployment Guides**: Step-by-step deployment instructions
- **Troubleshooting**: Common issues and solutions
- **API Documentation**: Service API documentation
- **Security Guidelines**: Security best practices and procedures

## 🤝 Contributing

### **Infrastructure Changes**

1. Create feature branch from `main`
2. Make changes in appropriate environment directory
3. Test changes in development environment
4. Create pull request with detailed description
5. Review and merge after approval

### **Monitoring Changes**

1. Update monitoring configurations
2. Test in development environment
3. Validate dashboards and alerts
4. Deploy to production after testing

## 📞 Support

For infrastructure and monitoring issues:

- **Documentation**: Check this README and docs/ directory
- **Issues**: Create GitHub issues for bugs and feature requests
- **Discussions**: Use GitHub discussions for questions and ideas

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Last Updated**: January 2025  
**Version**: 1.0.0  
**Maintainer**: MOSIP Infrastructure Team
