#!/bin/bash

###############################################################################
# Complete AWS Deployment Script - Vinod's Credit Card System
# Runs after Terraform infrastructure is ready
###############################################################################

set -e

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Configuration
export AWS_ACCOUNT_ID=489785350283
export AWS_REGION=us-east-1
export CLUSTER_NAME=vinod-credit-card-production

echo "============================================="
echo "  Complete Deployment Script"
echo "  AWS Account: $AWS_ACCOUNT_ID"
echo "  Region: $AWS_REGION"
echo "============================================="
echo ""

###############################################################################
# Step 1: Configure kubectl
###############################################################################
log_info "Configuring kubectl for EKS cluster..."
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

log_info "Verifying cluster access..."
kubectl get nodes

log_success "kubectl configured successfully"

###############################################################################
# Step 2: Build and Push Docker Images
###############################################################################
log_info "Building and pushing Docker images to ECR..."

# Login to ECR
log_info "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build and push backend
log_info "Building backend image..."
cd credit-card-backend
docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/vinod-credit-card-credit-card-backend-production:latest .

log_info "Pushing backend image..."
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/vinod-credit-card-credit-card-backend-production:latest
log_success "Backend image pushed"
cd ..

# Build and push frontend
log_info "Building frontend image..."
cd credit-card-frontend
docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/vinod-credit-card-credit-card-frontend-production:latest .

log_info "Pushing frontend image..."
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/vinod-credit-card-credit-card-frontend-production:latest
log_success "Frontend image pushed"
cd ..

###############################################################################
# Step 3: Update Kubernetes Manifests
###############################################################################
log_info "Updating Kubernetes manifests..."

mkdir -p k8s/processed
cp -r k8s/base/* k8s/processed/

# Update image references
find k8s/processed -type f -name "*.yaml" -exec sed -i.bak \
    "s|<AWS_ACCOUNT_ID>|${AWS_ACCOUNT_ID}|g; s|<AWS_REGION>|${AWS_REGION}|g" {} \;

# Get OpenAI API key from user
echo ""
log_warning "Enter your OpenAI API Key:"
read -s OPENAI_API_KEY

# Create secret
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
# Step 4: Deploy Application to Kubernetes
###############################################################################
log_info "Deploying application to EKS..."

# Create namespace
kubectl apply -f k8s/processed/namespace.yaml

# Deploy ConfigMap and Secrets
kubectl apply -f k8s/processed/configmap.yaml
kubectl apply -f k8s/processed/secret.yaml

# Deploy MongoDB
log_info "Deploying MongoDB..."
kubectl apply -f k8s/processed/mongodb-deployment.yaml
log_info "Waiting for MongoDB to be ready..."
kubectl wait --for=condition=ready pod -l app=mongodb -n credit-card-system --timeout=300s || true

# Deploy Backend
log_info "Deploying backend..."
kubectl apply -f k8s/processed/backend-deployment.yaml
log_info "Waiting for backend to be ready..."
kubectl wait --for=condition=ready pod -l app=backend -n credit-card-system --timeout=300s || true

# Deploy Frontend
log_info "Deploying frontend..."
kubectl apply -f k8s/processed/frontend-deployment.yaml
log_info "Waiting for frontend to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend -n credit-card-system --timeout=300s || true

# Deploy Ingress
log_info "Deploying ingress..."
kubectl apply -f k8s/processed/ingress.yaml

log_success "Application deployed to EKS"

###############################################################################
# Step 5: Get Application URL
###############################################################################
echo ""
log_info "Waiting for Load Balancer to be provisioned (3-5 minutes)..."
sleep 180

INGRESS_ADDRESS=""
for i in {1..20}; do
    INGRESS_ADDRESS=$(kubectl get ingress credit-card-ingress -n credit-card-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ -n "$INGRESS_ADDRESS" ]; then
        break
    fi
    log_info "Waiting for Load Balancer... (attempt $i/20)"
    sleep 15
done

###############################################################################
# Step 6: Display Summary
###############################################################################
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║           Deployment Complete!                           ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "AWS Account: $AWS_ACCOUNT_ID"
echo "Region: $AWS_REGION"
echo "Cluster: $CLUSTER_NAME"
echo ""

if [ -n "$INGRESS_ADDRESS" ]; then
    echo "🌐 Application URL: http://${INGRESS_ADDRESS}"
else
    echo "⏳ Load Balancer URL: (pending - check in a few minutes)"
    echo "   Run: kubectl get ingress -n credit-card-system"
fi

echo ""
echo "📊 Check Status:"
echo "  kubectl get pods -n credit-card-system"
echo "  kubectl get svc -n credit-card-system"
echo "  kubectl get ingress -n credit-card-system"
echo ""
log_success "Your Credit Card Recommendation System is LIVE! 🚀"
