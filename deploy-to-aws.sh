#!/bin/bash

###############################################################################
# Credit Card Recommendation System - AWS Deployment Script
# Author: Vinod Reddy Billipalli
# Description: Complete deployment script for EKS infrastructure and application
###############################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   Credit Card Recommendation System - AWS EKS Deployment      ║"
echo "║   by Vinod Reddy Billipalli                                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

###############################################################################
# Step 1: Prerequisites Check
###############################################################################
log_info "Checking prerequisites..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    log_error "Terraform is not installed. Please install it first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl is not installed. Please install it first."
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    log_error "Helm is not installed. Please install it first."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please install it first."
    exit 1
fi

log_success "All prerequisites are installed"

###############################################################################
# Step 2: AWS Configuration
###############################################################################
log_info "Validating AWS credentials..."

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
if [ -z "$AWS_ACCOUNT_ID" ]; then
    log_error "AWS credentials not configured. Run 'aws configure' first."
    exit 1
fi

# Get AWS Region
AWS_REGION=$(aws configure get region || echo "us-east-1")

log_success "AWS Account ID: $AWS_ACCOUNT_ID"
log_success "AWS Region: $AWS_REGION"

###############################################################################
# Step 3: Get OpenAI API Key
###############################################################################
echo ""
log_warning "OpenAI API Key Required"
echo "Please enter your OpenAI API Key (it will be hidden):"
read -s OPENAI_API_KEY

if [ -z "$OPENAI_API_KEY" ]; then
    log_error "OpenAI API Key is required"
    exit 1
fi

log_success "OpenAI API Key captured"

###############################################################################
# Step 4: Create S3 Bucket and DynamoDB Table for Terraform State
###############################################################################
echo ""
log_info "Setting up Terraform backend..."

BUCKET_NAME="vinod-credit-card-terraform-state-${AWS_ACCOUNT_ID}"
DYNAMODB_TABLE="terraform-state-lock"

# Create S3 bucket
if aws s3 ls "s3://${BUCKET_NAME}" 2>&1 | grep -q 'NoSuchBucket'; then
    log_info "Creating S3 bucket: ${BUCKET_NAME}"
    if [ "$AWS_REGION" == "us-east-1" ]; then
        aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${AWS_REGION}"
    else
        aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${AWS_REGION}" \
            --create-bucket-configuration LocationConstraint="${AWS_REGION}"
    fi

    # Enable versioning
    aws s3api put-bucket-versioning --bucket "${BUCKET_NAME}" \
        --versioning-configuration Status=Enabled

    # Enable encryption
    aws s3api put-bucket-encryption --bucket "${BUCKET_NAME}" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }'

    log_success "S3 bucket created: ${BUCKET_NAME}"
else
    log_success "S3 bucket already exists: ${BUCKET_NAME}"
fi

# Create DynamoDB table
if ! aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" --region "${AWS_REGION}" &> /dev/null; then
    log_info "Creating DynamoDB table: ${DYNAMODB_TABLE}"
    aws dynamodb create-table \
        --table-name "${DYNAMODB_TABLE}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "${AWS_REGION}"

    log_info "Waiting for DynamoDB table to be active..."
    aws dynamodb wait table-exists --table-name "${DYNAMODB_TABLE}" --region "${AWS_REGION}"
    log_success "DynamoDB table created: ${DYNAMODB_TABLE}"
else
    log_success "DynamoDB table already exists: ${DYNAMODB_TABLE}"
fi

###############################################################################
# Step 5: Update Terraform Configuration
###############################################################################
echo ""
log_info "Updating Terraform configuration..."

cd terraform

# Update backend configuration in versions.tf
sed -i.bak "s|bucket.*=.*\".*\"|bucket = \"${BUCKET_NAME}\"|g" versions.tf
sed -i.bak "s|region.*=.*\".*\"|region = \"${AWS_REGION}\"|g" versions.tf

log_success "Terraform configuration updated"

###############################################################################
# Step 6: Deploy Infrastructure with Terraform
###############################################################################
echo ""
log_info "Deploying AWS infrastructure with Terraform..."

# Initialize Terraform
log_info "Initializing Terraform..."
terraform init -upgrade

# Validate configuration
log_info "Validating Terraform configuration..."
terraform validate

# Plan
log_info "Creating Terraform plan..."
terraform plan -out=tfplan

# Ask for confirmation
echo ""
log_warning "Review the Terraform plan above."
read -p "Do you want to proceed with deployment? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    log_error "Deployment cancelled by user"
    exit 1
fi

# Apply
log_info "Applying Terraform configuration (this will take 15-20 minutes)..."
terraform apply tfplan

log_success "Infrastructure deployed successfully"

# Get cluster name
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
log_success "EKS Cluster Name: $CLUSTER_NAME"

cd ..

###############################################################################
# Step 7: Configure kubectl
###############################################################################
echo ""
log_info "Configuring kubectl..."

aws eks update-kubeconfig --region "${AWS_REGION}" --name "${CLUSTER_NAME}"

log_success "kubectl configured for cluster: ${CLUSTER_NAME}"

# Verify connection
log_info "Verifying cluster connection..."
kubectl get nodes

###############################################################################
# Step 8: Build and Push Docker Images
###############################################################################
echo ""
log_info "Building and pushing Docker images to ECR..."

# Login to ECR
log_info "Logging into ECR..."
aws ecr get-login-password --region "${AWS_REGION}" | \
    docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Backend Image
log_info "Building backend Docker image..."
cd credit-card-backend
BACKEND_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/vinod-credit-card-backend-production"
docker build -t "${BACKEND_REPO}:latest" .

log_info "Pushing backend image to ECR..."
docker push "${BACKEND_REPO}:latest"
log_success "Backend image pushed: ${BACKEND_REPO}:latest"
cd ..

# Frontend Image
log_info "Building frontend Docker image..."
cd credit-card-frontend
FRONTEND_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/vinod-credit-card-frontend-production"
docker build -t "${FRONTEND_REPO}:latest" .

log_info "Pushing frontend image to ECR..."
docker push "${FRONTEND_REPO}:latest"
log_success "Frontend image pushed: ${FRONTEND_REPO}:latest"
cd ..

###############################################################################
# Step 9: Update Kubernetes Manifests
###############################################################################
echo ""
log_info "Updating Kubernetes manifests..."

# Create temporary directory for processed manifests
mkdir -p k8s/processed
cp -r k8s/base/* k8s/processed/

# Update image references
find k8s/processed -type f -name "*.yaml" -exec sed -i.bak \
    "s|<AWS_ACCOUNT_ID>|${AWS_ACCOUNT_ID}|g; s|<AWS_REGION>|${AWS_REGION}|g; s|credit-card-backend|vinod-credit-card-backend-production|g; s|credit-card-frontend|vinod-credit-card-frontend-production|g" {} \;

# Update secret with OpenAI API Key
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

log_success "Kubernetes manifests updated"

###############################################################################
# Step 10: Deploy Application to EKS
###############################################################################
echo ""
log_info "Deploying application to EKS..."

# Create namespace
log_info "Creating namespace..."
kubectl apply -f k8s/processed/namespace.yaml

# Deploy ConfigMap and Secrets
log_info "Deploying ConfigMap and Secrets..."
kubectl apply -f k8s/processed/configmap.yaml
kubectl apply -f k8s/processed/secret.yaml

# Deploy MongoDB
log_info "Deploying MongoDB..."
kubectl apply -f k8s/processed/mongodb-deployment.yaml

# Wait for MongoDB to be ready
log_info "Waiting for MongoDB to be ready..."
kubectl wait --for=condition=ready pod -l app=mongodb -n credit-card-system --timeout=300s

# Deploy Backend
log_info "Deploying backend..."
kubectl apply -f k8s/processed/backend-deployment.yaml

# Wait for backend to be ready
log_info "Waiting for backend to be ready..."
kubectl wait --for=condition=ready pod -l app=backend -n credit-card-system --timeout=300s

# Deploy Frontend
log_info "Deploying frontend..."
kubectl apply -f k8s/processed/frontend-deployment.yaml

# Wait for frontend to be ready
log_info "Waiting for frontend to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend -n credit-card-system --timeout=300s

# Deploy Ingress
log_info "Deploying ingress..."
kubectl apply -f k8s/processed/ingress.yaml

log_success "Application deployed successfully"

###############################################################################
# Step 11: Get Application URL
###############################################################################
echo ""
log_info "Waiting for Load Balancer to be provisioned (this may take 3-5 minutes)..."

# Wait for ingress to get an address
sleep 60

INGRESS_ADDRESS=""
for i in {1..20}; do
    INGRESS_ADDRESS=$(kubectl get ingress credit-card-ingress -n credit-card-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ -n "$INGRESS_ADDRESS" ]; then
        break
    fi
    log_info "Waiting for Load Balancer... (attempt $i/20)"
    sleep 15
done

if [ -n "$INGRESS_ADDRESS" ]; then
    log_success "Application URL: http://${INGRESS_ADDRESS}"
else
    log_warning "Load Balancer not ready yet. Run this command to get the URL:"
    echo "kubectl get ingress credit-card-ingress -n credit-card-system"
fi

###############################################################################
# Step 12: Display Deployment Summary
###############################################################################
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              Deployment Summary                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "AWS Account ID:     ${AWS_ACCOUNT_ID}"
echo "AWS Region:         ${AWS_REGION}"
echo "EKS Cluster:        ${CLUSTER_NAME}"
echo "Namespace:          credit-card-system"
echo ""
if [ -n "$INGRESS_ADDRESS" ]; then
    echo "Application URL:    http://${INGRESS_ADDRESS}"
else
    echo "Application URL:    (Pending - check ingress status)"
fi
echo ""
echo "Backend ECR:        ${BACKEND_REPO}"
echo "Frontend ECR:       ${FRONTEND_REPO}"
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              Useful Commands                                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "View pods:          kubectl get pods -n credit-card-system"
echo "View services:      kubectl get svc -n credit-card-system"
echo "View ingress:       kubectl get ingress -n credit-card-system"
echo "View logs:          kubectl logs -f deployment/backend -n credit-card-system"
echo "Scale backend:      kubectl scale deployment backend --replicas=5 -n credit-card-system"
echo ""
log_success "Deployment completed successfully! 🚀"
