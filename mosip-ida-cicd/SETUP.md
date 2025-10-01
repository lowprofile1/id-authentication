# MOSIP ID Authentication CI/CD Setup Guide

This guide will help you set up the automated CI/CD pipeline for MOSIP ID Authentication Docker images.

## 🎯 Overview

The CI/CD pipeline automates:

- Building Maven artifacts
- Creating Docker images
- Pushing to AWS ECR
- Security scanning
- Testing
- Cleanup of old images

## 📋 Prerequisites

### 1. AWS Account Setup

#### Create IAM User

1. Go to AWS IAM Console
2. Create a new user: `mosip-ida-cicd`
3. Attach the following policies:
   - `AmazonEC2ContainerRegistryFullAccess`
   - Custom policy for ECR repository management:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:CreateRepository",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:BatchDeleteImage",
        "ecr:GetLifecyclePolicy",
        "ecr:PutLifecyclePolicy"
      ],
      "Resource": "*"
    }
  ]
}
```

#### Get AWS Credentials

1. Create access keys for the IAM user
2. Note down:
   - Access Key ID
   - Secret Access Key
   - AWS Account ID

### 2. GitHub Repository Setup

#### Fork or Clone

1. Fork this repository to your GitHub account
2. Or clone it to your local machine

#### Configure Secrets

Go to your repository → Settings → Secrets and variables → Actions

Add the following secrets:

| Secret Name             | Value          | Description           |
| ----------------------- | -------------- | --------------------- |
| `AWS_ACCOUNT_ID`        | `123456789012` | Your AWS Account ID   |
| `AWS_ACCESS_KEY_ID`     | `AKIA...`      | AWS Access Key ID     |
| `AWS_SECRET_ACCESS_KEY` | `...`          | AWS Secret Access Key |

#### Optional Secrets

| Secret Name           | Value                                                         | Description                |
| --------------------- | ------------------------------------------------------------- | -------------------------- |
| `SPRING_CONFIG_URL`   | `http://config-server:8888`                                   | Spring Config Server URL   |
| `ARTIFACTORY_URL`     | `http://artifactory:8081`                                     | Artifactory URL            |
| `BIOSDK_ZIP_PATH`     | `artifactory/libs-release-local/biosdk/mock/0.9/biosdk.zip`   | BioSDK path                |
| `DEMOSDK_ZIP_PATH`    | `artifactory/libs-release-local/demosdk/mock/0.9/demosdk.zip` | DemoSDK path               |
| `HSM_CLIENT_ZIP_PATH` | `artifactory/libs-release-local/hsm/client.zip`               | HSM Client path            |
| `IAM_ADAPTER_URL`     | `http://artifactory:8081/kernel-auth-adapter.jar`             | IAM Adapter URL            |
| `IS_GLOWROOT`         | `absent`                                                      | Enable Glowroot monitoring |

## 🚀 Quick Start

### 1. Setup ECR Repositories

Run the setup workflow to create ECR repositories:

1. Go to **Actions** tab
2. Select **Setup Repository**
3. Click **Run workflow**
4. Enter your AWS Account ID
5. Click **Run workflow**

### 2. Test the Pipeline

Run the build workflow:

1. Go to **Actions** tab
2. Select **Build and Push MOSIP ID Authentication to ECR**
3. Click **Run workflow**
4. Configure parameters:
   - Environment: `dev`
   - Version: (leave empty for auto-versioning)
   - Skip Tests: `false`
5. Click **Run workflow**

### 3. Verify Images

Check that images were created in ECR:

1. Go to AWS ECR Console
2. Navigate to your region
3. Look for repositories:
   - `mosip-authentication-service`
   - `mosip-authentication-internal-service`
   - `mosip-authentication-otp-service`

## 🔧 Configuration

### Workflow Triggers

The workflows are triggered by:

#### Build and Push (`build-and-push-ecr.yml`)

- Push to main/master/develop branches
- Pull requests
- Manual dispatch
- Release creation

#### Test Images (`test-docker-images.yml`)

- After successful build
- Manual dispatch

#### Cleanup (`cleanup-ecr.yml`)

- Weekly schedule (Sundays at 2 AM UTC)
- Manual dispatch

### Customizing Builds

#### Environment Variables

Edit the `env` section in workflow files:

```yaml
env:
  AWS_REGION: us-east-1
  ECR_REGISTRY: ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.us-east-1.amazonaws.com
  JAVA_VERSION: "11"
  MAVEN_VERSION: "3.8.7"
```

#### Build Arguments

Customize Docker build arguments:

```yaml
--build-arg spring_config_label=${{ needs.build-maven.outputs.version }}
--build-arg active_profile=${{ github.event.inputs.environment || 'dev' }}
--build-arg spring_config_url=${{ secrets.SPRING_CONFIG_URL || 'http://config-server:8888' }}
```

## 🧪 Local Testing

### Using the Test Scripts

#### Bash (Linux/macOS)

```bash
# Make script executable
chmod +x scripts/test-local.sh

# Test all services
./scripts/test-local.sh --registry 123456789012.dkr.ecr.us-east-1.amazonaws.com test-all

# Test specific service
./scripts/test-local.sh --registry 123456789012.dkr.ecr.us-east-1.amazonaws.com -v 1.2.1.0 test-service
```

#### PowerShell (Windows)

```powershell
# Test all services
.\scripts\test-local.ps1 -Registry "123456789012.dkr.ecr.us-east-1.amazonaws.com" -Command test-all

# Test integration
.\scripts\test-local.ps1 -Registry "123456789012.dkr.ecr.us-east-1.amazonaws.com" -Version "1.2.1.0" -Command test-integration
```

### Manual Testing

1. **Login to ECR:**

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
```

2. **Pull and test image:**

```bash
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/mosip-authentication-service:latest
docker run -p 8090:8090 -e active_profile_env=dev 123456789012.dkr.ecr.us-east-1.amazonaws.com/mosip-authentication-service:latest
```

## 📊 Monitoring

### GitHub Actions

- Check the **Actions** tab for workflow status
- View detailed logs for each job
- Review security scan results

### AWS ECR

- Navigate to ECR console
- View image repositories
- Check image tags and metadata
- Monitor storage usage

### Notifications

- GitHub will send email notifications for workflow failures
- Configure Slack notifications (optional)

## 🔒 Security

### Image Security

- Trivy vulnerability scanning on all images
- Base image security updates
- Non-root user execution in containers

### Access Control

- IAM-based ECR access
- GitHub secrets for credentials
- Workflow permissions

### Best Practices

- Regular security scans
- Keep base images updated
- Use specific image tags
- Implement image signing (optional)

## 🛠️ Troubleshooting

### Common Issues

#### 1. ECR Login Failed

**Error:** `Error: Cannot perform an interactive login from a non TTY device`

**Solution:**

- Verify AWS credentials are correct
- Check IAM permissions
- Ensure ECR repositories exist

#### 2. Docker Build Failed

**Error:** `The command '/bin/sh -c mvn clean package' returned a non-zero code`

**Solution:**

- Check Maven build logs
- Verify JAR files are present
- Review Dockerfile syntax
- Check for dependency issues

#### 3. Security Scan Failed

**Error:** `Trivy scan found critical vulnerabilities`

**Solution:**

- Review Trivy scan results
- Update base images
- Fix critical vulnerabilities
- Consider using different base image

#### 4. Test Failures

**Error:** `Health check failed`

**Solution:**

- Check container logs
- Verify port mappings
- Ensure environment variables are set
- Check service dependencies

### Debug Steps

1. **Check Workflow Logs:**

   - Go to Actions tab
   - Click on failed workflow
   - Review job logs

2. **Verify Secrets:**

   - Go to Settings → Secrets
   - Ensure all required secrets are set
   - Check secret values are correct

3. **Test AWS Access:**

   ```bash
   aws sts get-caller-identity
   aws ecr describe-repositories --region us-east-1
   ```

4. **Test Docker Locally:**
   ```bash
   docker run --rm hello-world
   docker build --help
   ```

## 📚 Advanced Usage

### Custom Environments

Create environment-specific configurations:

```yaml
# .github/workflows/build-and-push-ecr.yml
- name: Build Docker image
  run: |
    docker build \
      --build-arg active_profile=${{ github.event.inputs.environment || 'dev' }} \
      --build-arg spring_config_url=${{ secrets.SPRING_CONFIG_URL_${{ github.event.inputs.environment || 'DEV' }} }} \
      .
```

### Multi-Architecture Builds

Add multi-arch support:

```yaml
- name: Build and push multi-arch
  uses: docker/build-push-action@v4
  with:
    platforms: linux/amd64,linux/arm64
    push: true
    tags: ${{ env.ECR_REGISTRY }}/mosip-${{ matrix.service.name }}:${{ needs.build-maven.outputs.version }}
```

### Custom Cleanup Policies

Modify cleanup schedule and retention:

```yaml
# .github/workflows/cleanup-ecr.yml
on:
  schedule:
    - cron: "0 2 * * 0" # Every Sunday at 2 AM UTC
  workflow_dispatch:
    inputs:
      keep_days:
        default: "30"
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the workflows
5. Submit a pull request

## 📄 License

This project is licensed under the MPL 2.0 License.

## 🆘 Support

For issues and questions:

- Create an issue in this repository
- Check the MOSIP documentation
- Review AWS ECR documentation
- Check GitHub Actions documentation
