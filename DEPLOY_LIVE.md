# Go Live Deployment Guide

> **Complete step-by-step guide to deploy Credit Card Recommendation System to AWS EKS**
> **Author:** Vinod Reddy Billipalli

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] AWS Account with administrator access
- [ ] AWS CLI installed and configured (`aws configure`)
- [ ] Terraform installed (v1.5.0+)
- [ ] kubectl installed (v1.28.0+)
- [ ] Helm installed (v3.x)
- [ ] Docker installed and running
- [ ] OpenAI API Key (from https://platform.openai.com/api-keys)
- [ ] GitHub repository set up (for CI/CD)

---

## 🚀 Quick Start (Automated Deployment)

### Option 1: One-Command Deployment

```bash
./deploy-to-aws.sh
```

This script will:
1. ✅ Check all prerequisites
2. ✅ Validate AWS credentials
3. ✅ Create Terraform backend (S3 + DynamoDB)
4. ✅ Deploy infrastructure (VPC, EKS, ECR)
5. ✅ Build and push Docker images
6. ✅ Deploy application to Kubernetes
7. ✅ Provide application URL

**Estimated Time**: 20-25 minutes

---

## 📝 Manual Step-by-Step Deployment

If you prefer manual control or encounter issues with the automated script:

### Step 1: Verify AWS Credentials

```bash
# Check AWS credentials
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/your-username"
# }

# Set variables
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=$(aws configure get region || echo "us-east-1")

echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"
```

### Step 2: Create Terraform Backend

```bash
# Create S3 bucket for Terraform state
BUCKET_NAME="vinod-credit-card-terraform-state-${AWS_ACCOUNT_ID}"

aws s3api create-bucket \
  --bucket "${BUCKET_NAME}" \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
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

# Wait for table to be created
aws dynamodb wait table-exists --table-name terraform-state-lock --region us-east-1
```

### Step 3: Update Terraform Configuration

```bash
cd terraform

# Update backend bucket name in versions.tf
sed -i.bak "s|bucket.*=.*\".*\"|bucket = \"${BUCKET_NAME}\"|g" versions.tf
```

### Step 4: Deploy Infrastructure with Terraform

```bash
# Initialize Terraform
terraform init -upgrade

# Validate configuration
terraform validate

# Plan deployment
terraform plan -out=tfplan

# Review the plan carefully!
# Check estimated costs, resources to be created

# Apply the plan
terraform apply tfplan
```

**This will take 15-20 minutes**. Terraform will create:
- VPC with 3 public and 3 private subnets
- 3 NAT Gateways (one per AZ)
- EKS cluster with control plane
- EKS node group (3 t3.medium instances)
- ECR repositories for backend and frontend
- IAM roles for ALB controller

### Step 5: Configure kubectl

```bash
# Get cluster name from Terraform output
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)

# Update kubeconfig
aws eks update-kubeconfig --region "${AWS_REGION}" --name "${CLUSTER_NAME}"

# Verify connection
kubectl get nodes

# Expected output:
# NAME                         STATUS   ROLES    AGE   VERSION
# ip-10-0-x-x.ec2.internal     Ready    <none>   5m    v1.28.x
# ip-10-0-x-x.ec2.internal     Ready    <none>   5m    v1.28.x
# ip-10-0-x-x.ec2.internal     Ready    <none>   5m    v1.28.x

cd ..
```

### Step 6: Build and Push Docker Images

```bash
# Login to ECR
aws ecr get-login-password --region "${AWS_REGION}" | \
  docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Build and push backend
cd credit-card-backend
BACKEND_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/vinod-credit-card-backend-production"
docker build -t "${BACKEND_REPO}:latest" .
docker push "${BACKEND_REPO}:latest"
cd ..

# Build and push frontend
cd credit-card-frontend
FRONTEND_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/vinod-credit-card-frontend-production"
docker build -t "${FRONTEND_REPO}:latest" .
docker push "${FRONTEND_REPO}:latest"
cd ..
```

### Step 7: Update Kubernetes Manifests

```bash
# Create processed manifests directory
mkdir -p k8s/processed
cp -r k8s/base/* k8s/processed/

# Update image references
find k8s/processed -type f -name "*.yaml" -exec sed -i.bak \
  "s|<AWS_ACCOUNT_ID>|${AWS_ACCOUNT_ID}|g; s|<AWS_REGION>|${AWS_REGION}|g; s|credit-card-backend|vinod-credit-card-backend-production|g; s|credit-card-frontend|vinod-credit-card-frontend-production|g" {} \;
```

### Step 8: Configure Secrets

```bash
# Get OpenAI API Key
echo "Enter your OpenAI API Key:"
read -s OPENAI_API_KEY

# Create secret file
OPENAI_API_KEY_BASE64=$(echo -n "$OPENAI_API_KEY" | base64)
cat > k8s/processed/secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: backend-secrets
  namespace: credit-card-system
type: Opaque
data:
  OPENAI_API_KEY: ${OPENAI_API_KEY_BASE64}
EOF
```

### Step 9: Deploy Application to Kubernetes

```bash
# Create namespace
kubectl apply -f k8s/processed/namespace.yaml

# Deploy ConfigMap and Secrets
kubectl apply -f k8s/processed/configmap.yaml
kubectl apply -f k8s/processed/secret.yaml

# Deploy MongoDB
kubectl apply -f k8s/processed/mongodb-deployment.yaml
kubectl wait --for=condition=ready pod -l app=mongodb -n credit-card-system --timeout=300s

# Deploy Backend
kubectl apply -f k8s/processed/backend-deployment.yaml
kubectl wait --for=condition=ready pod -l app=backend -n credit-card-system --timeout=300s

# Deploy Frontend
kubectl apply -f k8s/processed/frontend-deployment.yaml
kubectl wait --for=condition=ready pod -l app=frontend -n credit-card-system --timeout=300s

# Deploy Ingress
kubectl apply -f k8s/processed/ingress.yaml
```

### Step 10: Get Application URL

```bash
# Wait for Load Balancer to be provisioned (3-5 minutes)
sleep 180

# Get the application URL
INGRESS_ADDRESS=$(kubectl get ingress credit-card-ingress -n credit-card-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "=============================================="
echo "Application URL: http://${INGRESS_ADDRESS}"
echo "=============================================="
```

---

## 📊 Setup Monitoring and Alerts

```bash
# Run monitoring setup script
./setup-monitoring.sh
```

This will:
- Create CloudWatch dashboard (`VinodCreditCardSystem`)
- Configure 5 CloudWatch alarms
- Set up SNS topic for email alerts
- Enable Container Insights for EKS

**Don't forget to confirm the SNS email subscription!**

---

## 🔄 Setup CI/CD (GitHub Actions)

### Step 1: Create GitHub Repository Secrets

Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions`

Add these secrets:

| Secret Name | Value | Command to Get |
|------------|-------|----------------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | `aws configure get aws_access_key_id` |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | `aws configure get aws_secret_access_key` |
| `AWS_ACCOUNT_ID` | Your AWS account ID | `aws sts get-caller-identity --query Account --output text` |
| `OPENAI_API_KEY` | Your OpenAI API key | From OpenAI dashboard |

### Step 2: Push Code to GitHub

```bash
git add .
git commit -m "Complete AWS EKS deployment setup"
git push origin main
```

This will trigger the CI/CD pipelines automatically!

### Step 3: Monitor Workflows

Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/actions`

You'll see three workflows:
- ✅ Backend CI/CD Pipeline
- ✅ Frontend CI/CD Pipeline
- ✅ Terraform CI/CD Pipeline

---

## ✅ Verification Checklist

After deployment, verify everything is working:

### 1. Infrastructure Verification

```bash
# Check EKS cluster
aws eks describe-cluster --name vinod-credit-card-production --region us-east-1

# Check nodes
kubectl get nodes

# Expected: 3 nodes in Ready state
```

### 2. Application Verification

```bash
# Check all pods
kubectl get pods -n credit-card-system

# Expected output:
# NAME                        READY   STATUS    RESTARTS   AGE
# backend-xxx                 1/1     Running   0          5m
# backend-yyy                 1/1     Running   0          5m
# backend-zzz                 1/1     Running   0          5m
# frontend-xxx                1/1     Running   0          5m
# frontend-yyy                1/1     Running   0          5m
# frontend-zzz                1/1     Running   0          5m
# mongodb-0                   1/1     Running   0          5m

# Check services
kubectl get svc -n credit-card-system

# Check ingress
kubectl get ingress -n credit-card-system
```

### 3. Health Check

```bash
# Get Load Balancer URL
INGRESS_URL=$(kubectl get ingress credit-card-ingress -n credit-card-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test backend health
curl http://${INGRESS_URL}/api/health

# Expected: {"status":"healthy","service":"credit-card-backend"}

# Test frontend (should return HTML)
curl http://${INGRESS_URL}/
```

### 4. Monitoring Verification

```bash
# Check CloudWatch dashboard
aws cloudwatch get-dashboard --dashboard-name VinodCreditCardSystem --region us-east-1

# Check alarms
aws cloudwatch describe-alarms --region us-east-1 | grep vinod-credit-card
```

---

## 🔍 Troubleshooting

### Issue 1: Pods not starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n credit-card-system

# Check logs
kubectl logs <pod-name> -n credit-card-system

# Common fixes:
# - Image pull errors: Verify ECR image exists
# - Crash loop: Check application logs for errors
# - Secret errors: Verify secret is created correctly
```

### Issue 2: Load Balancer not accessible

```bash
# Check ingress status
kubectl describe ingress credit-card-ingress -n credit-card-system

# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify ALB in AWS Console:
aws elbv2 describe-load-balancers --region us-east-1
```

### Issue 3: Backend can't connect to MongoDB

```bash
# Check MongoDB pod
kubectl get pod mongodb-0 -n credit-card-system
kubectl logs mongodb-0 -n credit-card-system

# Check MongoDB service
kubectl get svc mongodb-service -n credit-card-system

# Test connection from backend pod
kubectl exec -it <backend-pod> -n credit-card-system -- nc -zv mongodb-service 27017
```

### Issue 4: Terraform errors

```bash
# Common issues:
# - State lock: Delete lock from DynamoDB table
# - Resource already exists: Import existing resource or delete manually
# - Permission denied: Check IAM permissions

# Clean state lock
aws dynamodb delete-item \
  --table-name terraform-state-lock \
  --key '{"LockID":{"S":"vinod-credit-card-terraform-state-XXXXX/prod/terraform.tfstate"}}' \
  --region us-east-1
```

---

## 🎯 Useful Commands

### Scaling

```bash
# Scale backend manually
kubectl scale deployment backend --replicas=5 -n credit-card-system

# Scale frontend manually
kubectl scale deployment frontend --replicas=5 -n credit-card-system

# View HPA status
kubectl get hpa -n credit-card-system
```

### Monitoring

```bash
# Watch pods in real-time
kubectl get pods -n credit-card-system -w

# View logs (follow mode)
kubectl logs -f deployment/backend -n credit-card-system
kubectl logs -f deployment/frontend -n credit-card-system

# Check resource usage
kubectl top nodes
kubectl top pods -n credit-card-system
```

### Updates

```bash
# Update backend image
kubectl set image deployment/backend backend=<new-image> -n credit-card-system

# Rollback deployment
kubectl rollout undo deployment/backend -n credit-card-system

# Check rollout status
kubectl rollout status deployment/backend -n credit-card-system
```

---

## 💰 Cost Management

### Monitor Costs

```bash
# View current month costs
aws ce get-cost-and-usage \
  --time-period Start=2026-01-01,End=2026-01-31 \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE
```

### Estimated Monthly Costs
- **EKS Cluster**: $73
- **EC2 Instances** (3x t3.medium): $90
- **NAT Gateways** (3): $100
- **ALB**: $20
- **Other** (EBS, ECR, CloudWatch): $25
- **Total**: ~$308/month

### Cost Optimization Tips
1. Scale down to 2 nodes during off-hours
2. Use 1 NAT Gateway instead of 3 (saves $67/month)
3. Consider Reserved Instances for production (30-40% savings)
4. Use Spot Instances for non-critical workloads
5. Clean up unused ECR images regularly

---

## 🧹 Cleanup (Destroy Resources)

### Option 1: Destroy Everything

```bash
# Delete Kubernetes resources
kubectl delete namespace credit-card-system

# Wait for resources to be deleted
sleep 60

# Destroy Terraform infrastructure
cd terraform
terraform destroy -auto-approve
cd ..

# Delete S3 bucket (optional)
aws s3 rb s3://vinod-credit-card-terraform-state-${AWS_ACCOUNT_ID} --force

# Delete DynamoDB table (optional)
aws dynamodb delete-table --table-name terraform-state-lock --region us-east-1
```

### Option 2: Keep Infrastructure, Delete Application

```bash
# Just delete the application namespace
kubectl delete namespace credit-card-system
```

---

## 📚 Additional Resources

### Documentation
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Complete architecture documentation
- [GITHUB_SETUP.md](./GITHUB_SETUP.md) - GitHub Actions setup guide
- [AWS_INFRASTRUCTURE_SUMMARY.md](./AWS_INFRASTRUCTURE_SUMMARY.md) - Infrastructure summary

### AWS Console Links
- **EKS Cluster**: https://console.aws.amazon.com/eks/home?region=us-east-1#/clusters/vinod-credit-card-production
- **CloudWatch Dashboard**: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=VinodCreditCardSystem
- **ECR Repositories**: https://console.aws.amazon.com/ecr/repositories?region=us-east-1
- **Load Balancers**: https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#LoadBalancers

### Commands Reference
```bash
# Get cluster info
kubectl cluster-info

# Get all resources
kubectl get all -n credit-card-system

# Port forward (for local testing)
kubectl port-forward svc/backend-service 5001:5001 -n credit-card-system

# Execute commands in pod
kubectl exec -it <pod-name> -n credit-card-system -- /bin/bash

# View events
kubectl get events -n credit-card-system --sort-by='.lastTimestamp'
```

---

## 🎉 Success!

If you've reached here and your application is live, congratulations! 🚀

Your Credit Card Recommendation System is now:
- ✅ Running on AWS EKS
- ✅ Auto-scaling based on traffic
- ✅ Monitored with CloudWatch
- ✅ Deployed via CI/CD pipelines
- ✅ Highly available across 3 AZs
- ✅ Production-ready with security best practices

### Share Your Success
Your application URL: `http://<your-alb-url>`

---

**Questions or Issues?**
- Check [troubleshooting section](#-troubleshooting)
- Review logs: `kubectl logs -f deployment/backend -n credit-card-system`
- Check AWS Console for infrastructure status

**Created by Vinod Reddy Billipalli**
*Demonstrating DevSecOps, FinOps, and Cloud Engineering Excellence*
