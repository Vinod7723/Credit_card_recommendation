# Credit Card Recommendation System - AWS EKS Deployment Guide

This comprehensive guide covers deploying the Credit Card Recommendation System to AWS using EKS (Elastic Kubernetes Service), ECR (Elastic Container Registry), and complete CI/CD pipelines.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [AWS Infrastructure Setup](#aws-infrastructure-setup)
4. [GitHub Secrets Configuration](#github-secrets-configuration)
5. [Terraform Deployment](#terraform-deployment)
6. [Manual Kubernetes Deployment](#manual-kubernetes-deployment)
7. [CI/CD Pipeline Setup](#cicd-pipeline-setup)
8. [Monitoring and Logging](#monitoring-and-logging)
9. [Troubleshooting](#troubleshooting)
10. [Cost Optimization](#cost-optimization)

---

## Architecture Overview

### System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                     VPC (10.0.0.0/16)                     │  │
│  │                                                            │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │ Public Subnet│  │ Public Subnet│  │ Public Subnet│   │  │
│  │  │   us-east-1a │  │   us-east-1b │  │   us-east-1c │   │  │
│  │  │              │  │              │  │              │   │  │
│  │  │  NAT Gateway │  │  NAT Gateway │  │  NAT Gateway │   │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │  │
│  │                                                            │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │Private Subnet│  │Private Subnet│  │Private Subnet│   │  │
│  │  │   us-east-1a │  │   us-east-1b │  │   us-east-1c │   │  │
│  │  │              │  │              │  │              │   │  │
│  │  │  ┌────────┐  │  │  ┌────────┐  │  │  ┌────────┐  │   │  │
│  │  │  │EKS Node│  │  │  │EKS Node│  │  │  │EKS Node│  │   │  │
│  │  │  └────────┘  │  │  └────────┘  │  │  └────────┘  │   │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   Application Load Balancer                │  │
│  │                                                            │  │
│  │   ┌─────────────┐         ┌─────────────┐               │  │
│  │   │  Frontend   │         │   Backend   │               │  │
│  │   │  (React)    │────────▶│   (Flask)   │               │  │
│  │   │  Port: 80   │         │  Port: 5001 │               │  │
│  │   └─────────────┘         └─────────────┘               │  │
│  │                                  │                        │  │
│  │                                  ▼                        │  │
│  │                           ┌─────────────┐                │  │
│  │                           │   MongoDB   │                │  │
│  │                           │  Port: 27017│                │  │
│  │                           └─────────────┘                │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                       ECR Repositories                     │  │
│  │  • credit-card-backend-production                         │  │
│  │  • credit-card-frontend-production                        │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Components

- **EKS Cluster**: Managed Kubernetes cluster (v1.28)
- **VPC**: Multi-AZ deployment across 3 availability zones
- **ECR**: Docker image repositories for frontend and backend
- **Application Load Balancer**: Managed by AWS Load Balancer Controller
- **Horizontal Pod Autoscaler**: Auto-scaling based on CPU/Memory
- **MongoDB**: Persistent storage for application data
- **CloudWatch**: Monitoring and logging

---

## Prerequisites

### Required Tools

Install the following tools on your local machine:

```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Terraform
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Helm (optional)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Docker
sudo apt-get update
sudo apt-get install docker.io -y
sudo usermod -aG docker $USER
```

### AWS Account Requirements

- AWS Account with admin access
- AWS Access Key ID and Secret Access Key
- Sufficient service limits for:
  - EKS clusters (1)
  - EC2 instances (minimum 3 for node group)
  - VPCs (1)
  - Elastic IPs (3 for NAT Gateways)
  - Application Load Balancers (1)

### Estimated Monthly Costs

- **EKS Cluster**: $72/month
- **EC2 Instances** (3 x t3.medium): ~$90/month
- **NAT Gateways** (3 x $0.045/hour): ~$100/month
- **Application Load Balancer**: ~$20/month
- **Data Transfer**: Variable
- **Total Estimated**: ~$300-400/month

---

## AWS Infrastructure Setup

### Step 1: Configure AWS CLI

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output format: json

# Verify configuration
aws sts get-caller-identity
```

### Step 2: Create S3 Bucket for Terraform State

```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket credit-card-terraform-state \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket credit-card-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket credit-card-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

---

## GitHub Secrets Configuration

### Required GitHub Secrets

Navigate to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add the following secrets:

```
AWS_ACCESS_KEY_ID         = <your-aws-access-key-id>
AWS_SECRET_ACCESS_KEY     = <your-aws-secret-access-key>
AWS_ACCOUNT_ID            = <your-12-digit-aws-account-id>
OPENAI_API_KEY            = <your-openai-api-key>
REACT_APP_API_URL         = http://<alb-dns-name>/api
```

### How to Get AWS Account ID

```bash
aws sts get-caller-identity --query Account --output text
```

---

## Terraform Deployment

### Step 1: Initialize Terraform

```bash
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive
```

### Step 2: Plan Infrastructure

```bash
# Create execution plan
terraform plan \
  -var="aws_region=us-east-1" \
  -var="environment=production" \
  -out=tfplan

# Review the plan
# Ensure all resources are correct before applying
```

### Step 3: Apply Infrastructure

```bash
# Apply the plan
terraform apply tfplan

# This will create:
# - VPC with public/private subnets across 3 AZs
# - NAT Gateways in each AZ
# - EKS cluster with managed node group
# - ECR repositories for frontend and backend
# - IAM roles and policies
# - AWS Load Balancer Controller
# - Metrics Server for HPA

# Wait for completion (typically 15-20 minutes)
```

### Step 4: Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name credit-card-system-production

# Verify cluster access
kubectl cluster-info
kubectl get nodes
```

### Step 5: Get Terraform Outputs

```bash
# Display outputs
terraform output

# Get specific outputs
terraform output eks_cluster_name
terraform output eks_cluster_endpoint
terraform output ecr_repository_urls
```

---

## Manual Kubernetes Deployment

If you prefer to deploy manually instead of using CI/CD:

### Step 1: Build and Push Docker Images

#### Backend

```bash
cd credit-card-backend

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Build Docker image
docker build -t credit-card-backend:latest .

# Tag image
docker tag credit-card-backend:latest \
  <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/credit-card-backend-production:latest

# Push image
docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/credit-card-backend-production:latest
```

#### Frontend

```bash
cd credit-card-frontend

# Build Docker image
docker build -t credit-card-frontend:latest .

# Tag image
docker tag credit-card-frontend:latest \
  <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/credit-card-frontend-production:latest

# Push image
docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/credit-card-frontend-production:latest
```

### Step 2: Update Kubernetes Manifests

```bash
cd k8s/base

# Update image references in deployment files
sed -i "s|<AWS_ACCOUNT_ID>|<YOUR_AWS_ACCOUNT_ID>|g" backend-deployment.yaml
sed -i "s|<AWS_REGION>|us-east-1|g" backend-deployment.yaml

sed -i "s|<AWS_ACCOUNT_ID>|<YOUR_AWS_ACCOUNT_ID>|g" frontend-deployment.yaml
sed -i "s|<AWS_REGION>|us-east-1|g" frontend-deployment.yaml
```

### Step 3: Create Kubernetes Secret

```bash
# Create OpenAI API key secret
kubectl create secret generic backend-secrets \
  --from-literal=OPENAI_API_KEY=<your-openai-api-key> \
  --namespace=credit-card-system \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Step 4: Deploy to Kubernetes

```bash
# Deploy all resources
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f mongodb-deployment.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f ingress.yaml

# Wait for deployments
kubectl wait --for=condition=available --timeout=600s \
  deployment/backend -n credit-card-system

kubectl wait --for=condition=available --timeout=600s \
  deployment/frontend -n credit-card-system

kubectl wait --for=condition=available --timeout=600s \
  deployment/mongodb -n credit-card-system
```

### Step 5: Get Application URL

```bash
# Get ALB DNS name
kubectl get ingress credit-card-ingress -n credit-card-system

# Wait for ALB to be provisioned (5-10 minutes)
# Then access your application at:
# http://<alb-dns-name>
```

---

## CI/CD Pipeline Setup

### Pipeline Architecture

The project includes three GitHub Actions workflows:

1. **terraform-deploy.yml**: Infrastructure deployment
2. **backend-deploy.yml**: Backend application CI/CD
3. **frontend-deploy.yml**: Frontend application CI/CD

### Pipeline Triggers

#### Backend Pipeline

- **Push to main**: Builds, tests, and deploys to production
- **Push to develop**: Builds and tests only
- **Pull Request**: Runs linting and tests

#### Frontend Pipeline

- **Push to main**: Builds, tests, and deploys to production
- **Push to develop**: Builds and tests only
- **Pull Request**: Runs linting and tests

#### Terraform Pipeline

- **Push to main**: Plans and applies infrastructure changes
- **Pull Request**: Shows plan in PR comments
- **Manual trigger**: Can manually trigger apply or destroy

### Pipeline Flow

```
┌─────────────────────┐
│   Code Push (main)  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Lint & Test        │
│  • Flake8           │
│  • Black            │
│  • PyTest           │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Build Docker Image │
│  • Multi-stage      │
│  • Optimization     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Security Scan      │
│  • Trivy            │
│  • Vulnerability    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Push to ECR        │
│  • Tag: latest      │
│  • Tag: git-sha     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Deploy to EKS      │
│  • Update image     │
│  • Rolling update   │
│  • Health check     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Smoke Tests        │
│  • Health endpoint  │
│  • API tests        │
└─────────────────────┘
```

### First Deployment

```bash
# 1. Ensure all GitHub secrets are configured

# 2. Push infrastructure code
git add terraform/
git commit -m "Add Terraform infrastructure"
git push origin main

# Wait for terraform-deploy workflow to complete

# 3. Push application code
git add .
git commit -m "Add application code and CI/CD"
git push origin main

# This will trigger both backend-deploy and frontend-deploy workflows
```

---

## Monitoring and Logging

### Access Cluster Logs

```bash
# View pod logs
kubectl logs -f deployment/backend -n credit-card-system
kubectl logs -f deployment/frontend -n credit-card-system
kubectl logs -f deployment/mongodb -n credit-card-system

# View all pods in namespace
kubectl get pods -n credit-card-system

# Describe pod for troubleshooting
kubectl describe pod <pod-name> -n credit-card-system
```

### CloudWatch Integration

```bash
# View EKS cluster logs in CloudWatch
aws logs tail /aws/eks/credit-card-system-production/cluster --follow

# View application logs (if configured)
aws logs tail /aws/eks/credit-card-system-production/application --follow
```

### Metrics and Autoscaling

```bash
# View HPA status
kubectl get hpa -n credit-card-system

# View node metrics
kubectl top nodes

# View pod metrics
kubectl top pods -n credit-card-system
```

---

## Troubleshooting

### Common Issues

#### 1. Pods not starting

```bash
# Check pod status
kubectl get pods -n credit-card-system

# Check events
kubectl get events -n credit-card-system --sort-by='.lastTimestamp'

# Describe problematic pod
kubectl describe pod <pod-name> -n credit-card-system

# Check logs
kubectl logs <pod-name> -n credit-card-system
```

#### 2. Image pull errors

```bash
# Verify ECR repository exists
aws ecr describe-repositories --region us-east-1

# Ensure nodes can pull from ECR
kubectl get nodes -o yaml | grep -A 5 instanceProfile

# Check image exists
aws ecr describe-images \
  --repository-name credit-card-backend-production \
  --region us-east-1
```

#### 3. LoadBalancer not provisioning

```bash
# Check ingress status
kubectl describe ingress credit-card-ingress -n credit-card-system

# Check AWS Load Balancer Controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify IAM role for service account
kubectl describe sa aws-load-balancer-controller -n kube-system
```

#### 4. MongoDB connection issues

```bash
# Check MongoDB pod status
kubectl get pods -l app=mongodb -n credit-card-system

# Test MongoDB connection from backend pod
kubectl exec -it deployment/backend -n credit-card-system -- \
  mongosh mongodb://mongodb-service:27017/

# Check MongoDB logs
kubectl logs -l app=mongodb -n credit-card-system
```

### Debug Commands

```bash
# Get shell in backend pod
kubectl exec -it deployment/backend -n credit-card-system -- /bin/bash

# Port forward to test locally
kubectl port-forward -n credit-card-system deployment/backend 5001:5001
kubectl port-forward -n credit-card-system deployment/frontend 3000:80

# View all resources
kubectl get all -n credit-card-system

# Delete and recreate pod (force restart)
kubectl delete pod <pod-name> -n credit-card-system
```

---

## Cost Optimization

### Reduce Costs

1. **Use Spot Instances** for non-production environments
2. **Right-size EC2 instances** (use t3.small instead of t3.medium)
3. **Reduce node count** to 2 during low-traffic periods
4. **Use single NAT Gateway** instead of 3 (reduces HA)
5. **Delete unused resources** regularly

### Production Cost Savings

```terraform
# Modify terraform/variables.tf

# Use smaller instances
variable "node_instance_types" {
  default = ["t3.small"]  # Instead of t3.medium
}

# Reduce node count
variable "node_group_min_size" {
  default = 1  # Instead of 2
}

variable "node_group_desired" {
  default = 2  # Instead of 3
}
```

### Cleanup Resources

```bash
# Delete Kubernetes resources
kubectl delete namespace credit-card-system

# Destroy Terraform infrastructure
cd terraform
terraform destroy -auto-approve

# Delete S3 bucket and DynamoDB table
aws s3 rb s3://credit-card-terraform-state --force
aws dynamodb delete-table --table-name terraform-state-lock
```

---

## Next Steps

1. **Configure Custom Domain** with Route53 and ACM certificate
2. **Enable HTTPS** with AWS Certificate Manager
3. **Setup CI/CD notifications** (Slack, Discord, Email)
4. **Implement backup strategy** for MongoDB
5. **Add CloudWatch dashboards** for monitoring
6. **Configure log aggregation** (CloudWatch Logs Insights, Datadog)
7. **Implement blue-green deployments** for zero-downtime
8. **Add integration tests** to CI/CD pipeline
9. **Configure AWS WAF** for security
10. **Setup disaster recovery** plan

---

## Support

For issues or questions:
- GitHub Issues: https://github.com/Vinod7723/Credit_card_recommendation/issues
- AWS Documentation: https://docs.aws.amazon.com/eks/
- Kubernetes Documentation: https://kubernetes.io/docs/

---

**Last Updated**: January 2026
**Version**: 1.0.0
