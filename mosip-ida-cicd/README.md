# MOSIP ID Authentication CI/CD Pipeline

This repository contains GitHub Actions workflows for automating the build, test, and deployment of MOSIP ID Authentication Docker images to AWS ECR.

## 🚀 Features

- **Automated Maven Build**: Builds all authentication modules
- **Docker Image Building**: Creates optimized Docker images for all services
- **ECR Push**: Automatically pushes images to AWS ECR
- **Security Scanning**: Runs Trivy security scans on built images
- **Integration Testing**: Tests Docker images and service connectivity
- **Cleanup Automation**: Automatically cleans up old ECR images
- **Multi-Environment Support**: Supports dev, staging, and prod environments

## 📦 Services

This pipeline builds and deploys the following MOSIP ID Authentication services:

1. **authentication-service** (Port 8090)
2. **authentication-internal-service** (Port 8093)
3. **authentication-otp-service** (Port 8092)

## 🔧 Prerequisites

### AWS Setup

1. **AWS Account**: You need an AWS account with ECR access
2. **IAM User**: Create an IAM user with the following permissions:
   - `AmazonEC2ContainerRegistryFullAccess`
   - `ECR:CreateRepository`
   - `ECR:DescribeRepositories`
   - `ECR:BatchDeleteImage`
   - `ECR:ListImages`

### GitHub Secrets

Configure the following secrets in your GitHub repository:

#### Required Secrets

| Secret Name             | Description           | Example        |
| ----------------------- | --------------------- | -------------- |
| `AWS_ACCOUNT_ID`        | Your AWS Account ID   | `123456789012` |
| `AWS_ACCESS_KEY_ID`     | AWS Access Key ID     | `AKIA...`      |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | `...`          |

#### Optional Secrets

| Secret Name           | Description                | Default                                                       |
| --------------------- | -------------------------- | ------------------------------------------------------------- |
| `SPRING_CONFIG_URL`   | Spring Config Server URL   | `http://config-server:8888`                                   |
| `ARTIFACTORY_URL`     | Artifactory URL            | `http://artifactory:8081`                                     |
| `BIOSDK_ZIP_PATH`     | BioSDK zip path            | `artifactory/libs-release-local/biosdk/mock/0.9/biosdk.zip`   |
| `DEMOSDK_ZIP_PATH`    | DemoSDK zip path           | `artifactory/libs-release-local/demosdk/mock/0.9/demosdk.zip` |
| `HSM_CLIENT_ZIP_PATH` | HSM Client zip path        | `artifactory/libs-release-local/hsm/client.zip`               |
| `IAM_ADAPTER_URL`     | IAM Adapter URL            | `http://artifactory:8081/kernel-auth-adapter.jar`             |
| `IS_GLOWROOT`         | Enable Glowroot monitoring | `absent`                                                      |

## 🏗️ Workflows

### 1. Build and Push to ECR (`build-and-push-ecr.yml`)

**Triggers:**

- Push to main/master/develop branches
- Pull requests
- Manual dispatch

**Jobs:**

- **build-maven**: Builds Maven artifacts
- **build-and-push-docker**: Builds and pushes Docker images to ECR
- **security-scan**: Runs Trivy security scans
- **deployment-summary**: Generates deployment summary

### 2. Test Docker Images (`test-docker-images.yml`)

**Triggers:**

- After successful build workflow
- Manual dispatch

**Jobs:**

- **test-docker-images**: Tests individual Docker images
- **test-integration**: Tests service connectivity
- **generate-test-report**: Generates test summary

### 3. Cleanup ECR (`cleanup-ecr.yml`)

**Triggers:**

- Weekly schedule (Sundays at 2 AM UTC)
- Manual dispatch

**Jobs:**

- **cleanup-ecr**: Removes old and untagged images

## 🚀 Usage

### Manual Trigger

1. Go to the **Actions** tab in your GitHub repository
2. Select **Build and Push MOSIP ID Authentication to ECR**
3. Click **Run workflow**
4. Configure the parameters:
   - **Environment**: dev/staging/prod
   - **Version**: Custom version tag (optional)
   - **Skip Tests**: Skip Maven tests (optional)

### Automatic Trigger

The workflow automatically triggers on:

- Push to main/master/develop branches
- Pull requests
- Release creation

## 📋 Generated Images

After successful build, the following images will be available in ECR:

```
{ECR_REGISTRY}/mosip-authentication-service:{version}
{ECR_REGISTRY}/mosip-authentication-service:latest

{ECR_REGISTRY}/mosip-authentication-internal-service:{version}
{ECR_REGISTRY}/mosip-authentication-internal-service:latest

{ECR_REGISTRY}/mosip-authentication-otp-service:{version}
{ECR_REGISTRY}/mosip-authentication-otp-service:latest
```

## 🔍 Monitoring

### Build Status

- Check the **Actions** tab for workflow status
- View detailed logs for each job
- Review security scan results

### ECR Images

- Navigate to AWS ECR console
- View image repositories: `mosip-authentication-*`
- Check image tags and metadata

## 🛠️ Customization

### Environment Variables

Modify the `env` section in workflow files to customize:

- AWS region
- Java version
- Maven version
- ECR registry

### Build Arguments

Customize Docker build arguments in the `build-and-push-docker` job:

- Spring configuration
- Artifactory URLs
- SDK paths
- Monitoring settings

### Cleanup Policy

Adjust cleanup parameters in `cleanup-ecr.yml`:

- Retention period (default: 30 days)
- Dry run mode
- Repository selection

## 🔒 Security

### Image Security

- Trivy vulnerability scanning
- Base image security updates
- Non-root user execution

### Access Control

- IAM-based ECR access
- GitHub secrets for credentials
- Workflow permissions

## 📚 Troubleshooting

### Common Issues

1. **ECR Login Failed**

   - Verify AWS credentials
   - Check IAM permissions
   - Ensure ECR repositories exist

2. **Docker Build Failed**

   - Check Maven build logs
   - Verify JAR files are present
   - Review Dockerfile syntax

3. **Security Scan Failed**
   - Review Trivy scan results
   - Update base images if needed
   - Check for critical vulnerabilities

### Debug Steps

1. Check workflow logs in GitHub Actions
2. Verify all secrets are configured
3. Test AWS credentials manually
4. Review ECR repository permissions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the workflows
5. Submit a pull request

## 📄 License

This project is licensed under the MPL 2.0 License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For issues and questions:

- Create an issue in this repository
- Check the MOSIP documentation
- Review AWS ECR documentation
