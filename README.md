# MOSIP ID Authentication Service

This repository contains the MOSIP ID Authentication service components, including authentication modules, Kubernetes manifests, and CI/CD pipelines.

## 📁 Repository Structure

```
mosip-id-authentication/
├── authentication/                    # Authentication service modules
│   ├── authentication-core/         # Core authentication logic
│   ├── authentication-common/        # Shared authentication components
│   ├── authentication-service/       # Main authentication service
│   ├── authentication-otp-service/   # OTP authentication service
│   └── authentication-internal-service/ # Internal authentication service
├── k8s/                            # Kubernetes deployment manifests
│   ├── authentication-service.yaml
│   ├── authentication-otp-service.yaml
│   ├── authentication-internal-service.yaml
│   ├── ingress.yaml
│   ├── deploy.sh
│   └── INGRESS-README.md
├── .github/workflows/              # CI/CD pipelines
│   ├── build-and-push-ecr.yml      # Build and push to ECR
│   └── build-only.yml              # Build only workflow
├── db_scripts/                     # Database scripts
├── db_upgrade_scripts/             # Database upgrade scripts
├── docker/                         # Docker configurations
├── docs/                          # Documentation
├── Dockerfile
├── pom.xml
└── README.md
```

## 🚀 Quick Start

### **Prerequisites**

- Java 11+
- Maven 3.6+
- Docker
- Kubernetes cluster (EKS recommended)
- AWS CLI configured

### **Local Development**

```bash
# Clone the repository
git clone <repository-url>
cd mosip-id-authentication

# Build the project
mvn clean package -DskipTests

# Run locally
mvn spring-boot:run
```

### **Docker Build**

```bash
# Build Docker image
docker build -t mosip-authentication-service:latest .

# Run container
docker run -p 8090:8090 mosip-authentication-service:latest
```

### **Kubernetes Deployment**

```bash
# Deploy to Kubernetes
kubectl apply -f k8s/

# Check deployment status
kubectl get pods -n mosip-ida
kubectl get services -n mosip-ida
```

## 🔧 Services

### **Authentication Service**

- **Port**: 8090
- **Purpose**: Main authentication service
- **Endpoints**: `/v1/auth/*`
- **Health Check**: `/actuator/health`

### **Authentication OTP Service**

- **Port**: 8090
- **Purpose**: OTP-based authentication
- **Endpoints**: `/v1/otp/*`
- **Health Check**: `/actuator/health`

### **Authentication Internal Service**

- **Port**: 8090
- **Purpose**: Internal authentication operations
- **Endpoints**: `/v1/internal/*`
- **Health Check**: `/actuator/health`

## 🌐 Access URLs

### **Development Environment**

- **Authentication Service**: `http://authentication.mosip.local`
- **OTP Service**: `http://otp.mosip.local`
- **Internal Service**: `http://internal.mosip.local`

### **Production Environment**

- **Authentication Service**: `https://auth.mosip.io`
- **OTP Service**: `https://otp.mosip.io`
- **Internal Service**: `https://internal.mosip.io`

## 🔄 CI/CD Pipeline

### **Build and Push to ECR**

- **Trigger**: Push to `master`, `develop`, `main` branches
- **Actions**:
  - Build Maven project
  - Create Docker images
  - Push to Amazon ECR
  - Deploy to Kubernetes

### **Build Only**

- **Trigger**: Manual workflow dispatch
- **Actions**:
  - Build Maven project
  - Create local Docker images
  - Run tests

## 📊 Monitoring

### **Health Checks**

- **Endpoint**: `/actuator/health`
- **Metrics**: `/actuator/metrics`
- **Info**: `/actuator/info`

### **Logging**

- **Format**: JSON structured logging
- **Level**: Configurable via environment variables
- **Collection**: Fluentd for log aggregation

### **Metrics**

- **Prometheus**: Metrics collection
- **Grafana**: Visualization dashboards
- **Alerting**: Automated alerting on failures

## 🔒 Security

### **Authentication**

- **JWT Tokens**: Secure token-based authentication
- **OAuth 2.0**: Industry-standard authentication protocol
- **Multi-factor**: OTP and biometric authentication

### **Authorization**

- **Role-based Access Control (RBAC)**
- **Permission-based Authorization**
- **API Key Management**

### **Data Protection**

- **Encryption**: Data encrypted at rest and in transit
- **Secrets Management**: Kubernetes secrets for sensitive data
- **Network Security**: VPC and security groups

## 🛠️ Development

### **Code Structure**

- **Spring Boot**: Main framework
- **Maven**: Build and dependency management
- **Docker**: Containerization
- **Kubernetes**: Orchestration

### **Testing**

- **Unit Tests**: JUnit 5
- **Integration Tests**: Spring Boot Test
- **End-to-End Tests**: TestContainers

### **Code Quality**

- **SonarQube**: Code quality analysis
- **Checkstyle**: Code style enforcement
- **SpotBugs**: Static analysis

## 📚 Documentation

### **API Documentation**

- **Swagger UI**: Interactive API documentation
- **OpenAPI 3.0**: API specification
- **Postman Collection**: API testing

### **Deployment Guides**

- **Kubernetes**: Deployment instructions
- **Docker**: Container deployment
- **AWS**: Cloud deployment

### **Troubleshooting**

- **Common Issues**: Known problems and solutions
- **Log Analysis**: How to analyze logs
- **Performance Tuning**: Optimization guidelines

## 🤝 Contributing

### **Development Workflow**

1. Fork the repository
2. Create a feature branch
3. Make changes and test
4. Create a pull request
5. Code review and merge

### **Code Standards**

- **Java**: Follow Java coding standards
- **Spring Boot**: Follow Spring Boot best practices
- **Docker**: Follow Docker best practices
- **Kubernetes**: Follow Kubernetes best practices

## 📞 Support

### **Issues**

- **GitHub Issues**: Bug reports and feature requests
- **Documentation**: Check this README and docs/ directory
- **Community**: MOSIP community forums

### **Contact**

- **Email**: support@mosip.io
- **Slack**: MOSIP workspace
- **GitHub**: Repository discussions

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Last Updated**: January 2025  
**Version**: 1.0.0  
**Maintainer**: MOSIP Authentication Team
