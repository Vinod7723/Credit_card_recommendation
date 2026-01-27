# Quick Start Guide: AWS EKS Deployment

Get your Credit Card Recommendation System running on AWS EKS in 30 minutes!

## Prerequisites Checklist

- [ ] AWS Account with admin access
- [ ] AWS CLI installed and configured
- [ ] kubectl installed
- [ ] Terraform installed (v1.5.0+)
- [ ] Docker installed
- [ ] GitHub repository access
- [ ] OpenAI API key

## Step-by-Step Deployment

### 1. Configure AWS Credentials (2 minutes)

```bash
aws configure
# Enter AWS Access Key ID
# Enter AWS Secret Access Key
# Default region: us-east-1
# Default output format: json

# Verify
aws sts get-caller-identity
```

### 2. Create S3 Bucket for Terraform State (2 minutes)

```bash
# Create bucket
aws s3api create-bucket \
  --bucket credit-card-terraform-state \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket credit-card-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 3. Deploy Infrastructure with Terraform (15-20 minutes)

```bash
cd terraform

# Initialize
terraform init

# Review plan
terraform plan \
  -var="aws_region=us-east-1" \
  -var="environment=production" \
  -out=tfplan

# Apply
terraform apply tfplan

# Wait for completion (15-20 minutes)
```

### 4. Configure kubectl (1 minute)

```bash
# Update kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name credit-card-system-production

# Verify
kubectl get nodes
```

### 5. Setup GitHub Secrets (2 minutes)

Go to GitHub → Repository → Settings → Secrets and variables → Actions

Add these secrets:

```
AWS_ACCESS_KEY_ID         = <from step 1>
AWS_SECRET_ACCESS_KEY     = <from step 1>
AWS_ACCOUNT_ID            = <12-digit AWS account ID>
OPENAI_API_KEY            = <your OpenAI API key>
```

Get your AWS Account ID:
```bash
aws sts get-caller-identity --query Account --output text
```

### 6. Deploy Application via CI/CD (5-10 minutes)

```bash
# Commit and push your code
git add .
git commit -m "Initial deployment to AWS EKS"
git push origin main

# This triggers GitHub Actions workflows
# Monitor at: https://github.com/<your-username>/<repo>/actions
```

Alternatively, manual deployment:

```bash
# Build and push backend
cd credit-card-backend
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com
docker build -t credit-card-backend:latest .
docker tag credit-card-backend:latest $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/credit-card-backend-production:latest
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/credit-card-backend-production:latest

# Build and push frontend
cd ../credit-card-frontend
docker build -t credit-card-frontend:latest .
docker tag credit-card-frontend:latest $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/credit-card-frontend-production:latest
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/credit-card-frontend-production:latest

# Deploy to Kubernetes
cd ../k8s/base
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
sed -i "s|<AWS_ACCOUNT_ID>|$AWS_ACCOUNT_ID|g" backend-deployment.yaml frontend-deployment.yaml
sed -i "s|<AWS_REGION>|us-east-1|g" backend-deployment.yaml frontend-deployment.yaml

# Create secret
kubectl create secret generic backend-secrets \
  --from-literal=OPENAI_API_KEY=<your-key> \
  --namespace=credit-card-system \
  --dry-run=client -o yaml | kubectl apply -f -

# Apply manifests
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f mongodb-deployment.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f ingress.yaml
```

### 7. Get Application URL (1 minute)

```bash
# Get ALB DNS name
kubectl get ingress credit-card-ingress -n credit-card-system

# Output example:
# NAME                   CLASS    HOSTS   ADDRESS                                      PORTS   AGE
# credit-card-ingress    alb      *       k8s-creditca-creditca-xxxxx.us-east-1.elb.amazonaws.com   80      5m
```

Wait 5-10 minutes for ALB to be fully provisioned, then visit:
```
http://<ALB-DNS-NAME>
```

### 8. Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n credit-card-system

# Expected output:
# NAME                        READY   STATUS    RESTARTS   AGE
# backend-xxxxx-xxxxx         1/1     Running   0          5m
# frontend-xxxxx-xxxxx        1/1     Running   0          5m
# mongodb-xxxxx-xxxxx         1/1     Running   0          5m

# Check services
kubectl get svc -n credit-card-system

# Test backend health
ALB_URL=$(kubectl get ingress credit-card-ingress -n credit-card-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$ALB_URL/api/health

# Should return: {"status":"healthy","service":"credit-card-backend"}
```

## What Was Created?

### AWS Resources

- ✅ VPC with 3 public and 3 private subnets across 3 AZs
- ✅ 3 NAT Gateways (one per AZ for high availability)
- ✅ Internet Gateway
- ✅ EKS Cluster (Kubernetes 1.28)
- ✅ EKS Node Group (2-10 t3.medium instances)
- ✅ 2 ECR Repositories (backend, frontend)
- ✅ Application Load Balancer (ALB)
- ✅ IAM Roles and Policies
- ✅ Security Groups
- ✅ CloudWatch Log Groups

### Kubernetes Resources

- ✅ Namespace: credit-card-system
- ✅ Deployments: backend (3 replicas), frontend (3 replicas), mongodb (1 replica)
- ✅ Services: backend-service, frontend-service, mongodb-service
- ✅ Ingress: ALB with routing rules
- ✅ ConfigMaps: Application configuration
- ✅ Secrets: OpenAI API key
- ✅ HPA: Auto-scaling for backend and frontend
- ✅ PersistentVolumeClaim: MongoDB data storage

### CI/CD Pipelines

- ✅ Backend CI/CD: Lint → Test → Build → Scan → Push → Deploy
- ✅ Frontend CI/CD: Lint → Test → Build → Scan → Push → Deploy
- ✅ Terraform CI/CD: Validate → Plan → Apply
- ✅ Security scanning with Trivy
- ✅ Automated deployments on push to main

## Common Commands

### View Logs

```bash
# Backend logs
kubectl logs -f deployment/backend -n credit-card-system

# Frontend logs
kubectl logs -f deployment/frontend -n credit-card-system

# MongoDB logs
kubectl logs -f deployment/mongodb -n credit-card-system
```

### Scale Applications

```bash
# Scale backend
kubectl scale deployment backend --replicas=5 -n credit-card-system

# Scale frontend
kubectl scale deployment frontend --replicas=5 -n credit-card-system
```

### Update Application

```bash
# After code changes, rebuild and push
docker build -t credit-card-backend:v2 .
docker tag credit-card-backend:v2 $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/credit-card-backend-production:v2
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/credit-card-backend-production:v2

# Update deployment
kubectl set image deployment/backend backend=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/credit-card-backend-production:v2 -n credit-card-system

# Watch rollout
kubectl rollout status deployment/backend -n credit-card-system
```

### Monitor Resources

```bash
# View HPA status
kubectl get hpa -n credit-card-system

# View resource usage
kubectl top nodes
kubectl top pods -n credit-card-system

# View events
kubectl get events -n credit-card-system --sort-by='.lastTimestamp'
```

## Cleanup

### Delete Application Only

```bash
kubectl delete namespace credit-card-system
```

### Delete Everything (including infrastructure)

```bash
# Delete Kubernetes resources
kubectl delete namespace credit-card-system

# Destroy infrastructure
cd terraform
terraform destroy -auto-approve

# Delete S3 bucket and DynamoDB table
aws s3 rb s3://credit-card-terraform-state --force
aws dynamodb delete-table --table-name terraform-state-lock --region us-east-1

# Delete ECR images
aws ecr batch-delete-image \
  --repository-name credit-card-backend-production \
  --image-ids imageTag=latest \
  --region us-east-1

aws ecr batch-delete-image \
  --repository-name credit-card-frontend-production \
  --image-ids imageTag=latest \
  --region us-east-1
```

## Estimated Costs

- **Development** (2 nodes, single NAT): ~$150/month
- **Production** (3 nodes, 3 NAT): ~$350/month

## Troubleshooting

### Issue: Pods not starting

```bash
kubectl describe pod <pod-name> -n credit-card-system
kubectl logs <pod-name> -n credit-card-system
```

### Issue: Can't access application

```bash
# Check ingress
kubectl describe ingress credit-card-ingress -n credit-card-system

# Check ALB controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Wait 5-10 minutes for ALB provisioning
```

### Issue: Image pull error

```bash
# Verify ECR repo exists
aws ecr describe-repositories --region us-east-1

# Check image is pushed
aws ecr describe-images --repository-name credit-card-backend-production --region us-east-1
```

## Next Steps

1. Configure custom domain with Route53
2. Add SSL/TLS certificate with ACM
3. Setup monitoring with CloudWatch
4. Configure backup for MongoDB
5. Add integration tests to CI/CD
6. Setup staging environment
7. Configure AWS WAF for security

## Support

- Full Documentation: [DEPLOYMENT.md](DEPLOYMENT.md)
- GitHub Issues: https://github.com/Vinod7723/Credit_card_recommendation/issues
- AWS Support: https://console.aws.amazon.com/support/

---

**Deployment Complete!** 🚀

Your Credit Card Recommendation System is now running on AWS EKS with:
- High Availability (Multi-AZ)
- Auto-Scaling (HPA)
- Load Balancing (ALB)
- Automated CI/CD
- Container Security Scanning
- Production-Ready Infrastructure
