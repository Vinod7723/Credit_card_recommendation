#!/bin/bash

# =====================================================
# Credit Card Recommendation System - AWS Deployment
# =====================================================
# This script will deploy your application to AWS EKS
# Run time: ~45 minutes
# =====================================================

set -e  # Exit on any error

echo "🚀 Starting AWS EKS Deployment"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# =====================================================
# STEP 1: Prerequisites Check
# =====================================================
echo -e "${BLUE}Step 1: Checking prerequisites...${NC}"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not found. Install from: https://aws.amazon.com/cli/${NC}"
    exit 1
fi
echo -e "${GREEN}✅ AWS CLI found${NC}"

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not found. Install from: https://kubernetes.io/docs/tasks/tools/${NC}"
    exit 1
fi
echo -e "${GREEN}✅ kubectl found${NC}"

# Check terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform not found. Install from: https://www.terraform.io/downloads${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Terraform found${NC}"

# Check helm
if ! command -v helm &> /dev/null; then
    echo -e "${RED}❌ Helm not found. Install from: https://helm.sh/docs/intro/install/${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Helm found${NC}"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Run: aws configure${NC}"
    exit 1
fi
echo -e "${GREEN}✅ AWS credentials configured${NC}"

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✅ AWS Account ID: $AWS_ACCOUNT_ID${NC}"
echo ""

# =====================================================
# STEP 2: Set OpenAI API Key
# =====================================================
echo -e "${BLUE}Step 2: OpenAI API Key${NC}"
echo "Please enter your OpenAI API key:"
read -s OPENAI_API_KEY
export OPENAI_API_KEY
echo -e "${GREEN}✅ OpenAI API key set${NC}"
echo ""

# =====================================================
# STEP 3: Create Terraform State Backend
# =====================================================
echo -e "${BLUE}Step 3: Creating Terraform state backend...${NC}"

BUCKET_NAME="credit-card-terraform-state-${AWS_ACCOUNT_ID}"

# Create S3 bucket
if aws s3 ls "s3://${BUCKET_NAME}" 2>&1 | grep -q 'NoSuchBucket'; then
    aws s3api create-bucket \
      --bucket "${BUCKET_NAME}" \
      --region us-east-1
    echo -e "${GREEN}✅ S3 bucket created${NC}"
else
    echo -e "${GREEN}✅ S3 bucket already exists${NC}"
fi

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled
echo -e "${GREEN}✅ Versioning enabled${NC}"

# Create DynamoDB table
if ! aws dynamodb describe-table --table-name terraform-state-lock --region us-east-1 &> /dev/null; then
    aws dynamodb create-table \
      --table-name terraform-state-lock \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST \
      --region us-east-1
    echo -e "${GREEN}✅ DynamoDB table created${NC}"
else
    echo -e "${GREEN}✅ DynamoDB table already exists${NC}"
fi
echo ""

# =====================================================
# STEP 4: Update Terraform Backend Configuration
# =====================================================
echo -e "${BLUE}Step 4: Updating Terraform configuration...${NC}"

cd terraform
sed -i.bak "s/credit-card-terraform-state/${BUCKET_NAME}/g" main.tf
rm -f main.tf.bak
echo -e "${GREEN}✅ Terraform configuration updated${NC}"
echo ""

# =====================================================
# STEP 5: Deploy Infrastructure
# =====================================================
echo -e "${BLUE}Step 5: Deploying infrastructure (this takes 15-20 minutes)...${NC}"

# Initialize Terraform
terraform init
echo -e "${GREEN}✅ Terraform initialized${NC}"

# Plan
terraform plan -out=tfplan
echo -e "${GREEN}✅ Terraform plan created${NC}"

# Apply
echo "Starting infrastructure deployment..."
terraform apply -auto-approve tfplan
echo -e "${GREEN}✅ Infrastructure deployed${NC}"

# Get outputs
export EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
echo -e "${GREEN}✅ EKS Cluster: $EKS_CLUSTER_NAME${NC}"
echo ""

# =====================================================
# STEP 6: Configure kubectl
# =====================================================
echo -e "${BLUE}Step 6: Configuring kubectl...${NC}"

aws eks update-kubeconfig --region us-east-1 --name ${EKS_CLUSTER_NAME}
kubectl get nodes
echo -e "${GREEN}✅ kubectl configured${NC}"
echo ""

# =====================================================
# STEP 7: Build and Push Docker Images
# =====================================================
echo -e "${BLUE}Step 7: Building and pushing Docker images...${NC}"

cd ..

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com
echo -e "${GREEN}✅ Logged into ECR${NC}"

# Build and push backend
cd credit-card-backend
echo "Building backend image..."
docker build -t credit-card-backend:latest .
docker tag credit-card-backend:latest \
  ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/credit-card-backend-production:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/credit-card-backend-production:latest
echo -e "${GREEN}✅ Backend image pushed${NC}"

# Build and push frontend
cd ../credit-card-frontend
echo "Building frontend image..."
docker build -t credit-card-frontend:latest .
docker tag credit-card-frontend:latest \
  ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/credit-card-frontend-production:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/credit-card-frontend-production:latest
echo -e "${GREEN}✅ Frontend image pushed${NC}"
echo ""

# =====================================================
# STEP 8: Deploy to Kubernetes
# =====================================================
echo -e "${BLUE}Step 8: Deploying application to Kubernetes...${NC}"

cd ../k8s/base

# Update manifests with AWS Account ID
sed -i.bak "s/<AWS_ACCOUNT_ID>/${AWS_ACCOUNT_ID}/g" backend-deployment.yaml frontend-deployment.yaml
sed -i.bak "s/<AWS_REGION>/us-east-1/g" backend-deployment.yaml frontend-deployment.yaml
rm -f *.bak
echo -e "${GREEN}✅ Manifests updated${NC}"

# Create secret
kubectl create secret generic backend-secrets \
  --from-literal=OPENAI_API_KEY=${OPENAI_API_KEY} \
  --namespace=credit-card-system \
  --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✅ Secrets created${NC}"

# Deploy all resources
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f mongodb-deployment.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f ingress.yaml
echo -e "${GREEN}✅ Resources deployed${NC}"

# Wait for deployments
echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=600s \
  deployment/backend deployment/frontend deployment/mongodb \
  -n credit-card-system
echo -e "${GREEN}✅ All deployments ready${NC}"
echo ""

# =====================================================
# STEP 9: Get Application URL
# =====================================================
echo -e "${BLUE}Step 9: Getting application URL...${NC}"

echo "Waiting for load balancer to be provisioned (5-10 minutes)..."
sleep 60

export APP_URL=$(kubectl get ingress credit-card-ingress -n credit-card-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -z "$APP_URL" ]; then
    echo -e "${RED}⏳ ALB is still provisioning. Run this command in 5 minutes:${NC}"
    echo "kubectl get ingress credit-card-ingress -n credit-card-system"
else
    echo -e "${GREEN}✅ Application URL: http://$APP_URL${NC}"
fi
echo ""

# =====================================================
# DEPLOYMENT COMPLETE
# =====================================================
echo -e "${GREEN}======================================"
echo "🎉 DEPLOYMENT COMPLETE!"
echo "======================================${NC}"
echo ""
echo "📊 Deployment Summary:"
echo "  - EKS Cluster: $EKS_CLUSTER_NAME"
echo "  - Application URL: http://$APP_URL"
echo "  - Namespace: credit-card-system"
echo ""
echo "📝 Next Steps:"
echo "  1. Wait 5-10 minutes for ALB to fully provision"
echo "  2. Visit: http://$APP_URL"
echo "  3. Test backend health: curl http://$APP_URL/api/health"
echo ""
echo "🔍 Useful Commands:"
echo "  - View pods: kubectl get pods -n credit-card-system"
echo "  - View logs: kubectl logs -f deployment/backend -n credit-card-system"
echo "  - View ingress: kubectl get ingress -n credit-card-system"
echo ""
echo -e "${GREEN}✅ Your application is LIVE on AWS!${NC}"
echo ""
