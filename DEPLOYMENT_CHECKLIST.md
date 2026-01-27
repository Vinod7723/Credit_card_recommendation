# AWS Deployment Checklist

Use this checklist to deploy your Credit Card Recommendation System to AWS EKS.

## Pre-Deployment Checklist

### Prerequisites
- [ ] AWS Account created
- [ ] AWS CLI installed (`aws --version`)
- [ ] kubectl installed (`kubectl version --client`)
- [ ] Terraform installed (`terraform version`)
- [ ] Docker installed (`docker --version`)
- [ ] Git repository setup
- [ ] OpenAI API key obtained

### AWS Setup
- [ ] AWS credentials configured (`aws configure`)
- [ ] AWS account ID obtained (`aws sts get-caller-identity`)
- [ ] IAM user has admin permissions
- [ ] Service limits checked (EKS, EC2, VPC)
- [ ] AWS region selected (default: us-east-1)

---

## Deployment Steps

### Phase 1: Terraform State Setup (5 minutes)

- [ ] Create S3 bucket for Terraform state
  ```bash
  aws s3api create-bucket --bucket credit-card-terraform-state --region us-east-1
  ```
- [ ] Enable S3 bucket versioning
  ```bash
  aws s3api put-bucket-versioning --bucket credit-card-terraform-state --versioning-configuration Status=Enabled
  ```
- [ ] Create DynamoDB table for state locking
  ```bash
  aws dynamodb create-table --table-name terraform-state-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region us-east-1
  ```

### Phase 2: Infrastructure Deployment (20 minutes)

- [ ] Navigate to terraform directory (`cd terraform`)
- [ ] Initialize Terraform (`terraform init`)
- [ ] Review variables in `variables.tf`
- [ ] Create execution plan (`terraform plan -out=tfplan`)
- [ ] Review plan output carefully
- [ ] Apply infrastructure (`terraform apply tfplan`)
- [ ] Wait for completion (15-20 minutes)
- [ ] Note outputs (cluster name, ECR URLs)

### Phase 3: Kubernetes Configuration (5 minutes)

- [ ] Update kubeconfig
  ```bash
  aws eks update-kubeconfig --region us-east-1 --name credit-card-system-production
  ```
- [ ] Verify cluster access (`kubectl get nodes`)
- [ ] Check all nodes are Ready
- [ ] Verify namespaces (`kubectl get namespaces`)
- [ ] Check system pods (`kubectl get pods -n kube-system`)

### Phase 4: GitHub Configuration (5 minutes)

- [ ] Go to GitHub repository settings
- [ ] Navigate to Secrets and variables → Actions
- [ ] Add `AWS_ACCESS_KEY_ID`
- [ ] Add `AWS_SECRET_ACCESS_KEY`
- [ ] Add `AWS_ACCOUNT_ID`
- [ ] Add `OPENAI_API_KEY`
- [ ] Add `REACT_APP_API_URL` (set after ALB is created)

### Phase 5: Application Deployment (10 minutes)

#### Option A: CI/CD Deployment (Recommended)
- [ ] Commit all changes (`git add .`)
- [ ] Create commit (`git commit -m "Deploy to AWS EKS"`)
- [ ] Push to main (`git push origin main`)
- [ ] Monitor GitHub Actions workflows
- [ ] Wait for backend pipeline to complete
- [ ] Wait for frontend pipeline to complete
- [ ] Check workflow logs for errors

#### Option B: Manual Deployment
- [ ] Login to ECR
  ```bash
  aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com
  ```
- [ ] Build backend image (`cd credit-card-backend && docker build -t credit-card-backend:latest .`)
- [ ] Tag backend image
- [ ] Push backend image
- [ ] Build frontend image (`cd credit-card-frontend && docker build -t credit-card-frontend:latest .`)
- [ ] Tag frontend image
- [ ] Push frontend image
- [ ] Update Kubernetes manifests with AWS account ID and region
- [ ] Create Kubernetes secret for OpenAI API key
- [ ] Apply namespace (`kubectl apply -f k8s/base/namespace.yaml`)
- [ ] Apply ConfigMap (`kubectl apply -f k8s/base/configmap.yaml`)
- [ ] Apply MongoDB deployment (`kubectl apply -f k8s/base/mongodb-deployment.yaml`)
- [ ] Apply backend deployment (`kubectl apply -f k8s/base/backend-deployment.yaml`)
- [ ] Apply frontend deployment (`kubectl apply -f k8s/base/frontend-deployment.yaml`)
- [ ] Apply ingress (`kubectl apply -f k8s/base/ingress.yaml`)

### Phase 6: Verification (10 minutes)

- [ ] Check all pods are running
  ```bash
  kubectl get pods -n credit-card-system
  ```
- [ ] Verify pod status (all should be Running)
- [ ] Check backend logs (`kubectl logs -l app=backend -n credit-card-system --tail=50`)
- [ ] Check frontend logs (`kubectl logs -l app=frontend -n credit-card-system --tail=50`)
- [ ] Check MongoDB logs (`kubectl logs -l app=mongodb -n credit-card-system --tail=50`)
- [ ] Verify services are created (`kubectl get svc -n credit-card-system`)
- [ ] Check ingress status (`kubectl get ingress -n credit-card-system`)
- [ ] Wait for ALB DNS name to appear (5-10 minutes)
- [ ] Check HPA status (`kubectl get hpa -n credit-card-system`)

### Phase 7: Application Testing (10 minutes)

- [ ] Get ALB URL
  ```bash
  kubectl get ingress credit-card-ingress -n credit-card-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
  ```
- [ ] Wait for ALB to be fully provisioned (5-10 minutes)
- [ ] Test backend health endpoint
  ```bash
  curl http://<ALB-URL>/api/health
  ```
- [ ] Expected response: `{"status":"healthy","service":"credit-card-backend"}`
- [ ] Test frontend health endpoint
  ```bash
  curl http://<ALB-URL>/health
  ```
- [ ] Open application in browser (`http://<ALB-URL>`)
- [ ] Test greeting functionality ("hi" or "hello")
- [ ] Test card recommendation ("I need a travel card")
- [ ] Test order creation flow
- [ ] Test order tracking
- [ ] Test order cancellation
- [ ] Verify all features work correctly

---

## Post-Deployment Checklist

### Security
- [ ] Review security group rules
- [ ] Verify secrets are not exposed in logs
- [ ] Check image vulnerability scan results
- [ ] Review IAM role permissions
- [ ] Enable CloudTrail logging
- [ ] Configure AWS Config rules

### Monitoring
- [ ] Setup CloudWatch dashboards
- [ ] Configure CloudWatch alarms for:
  - [ ] High CPU usage
  - [ ] High memory usage
  - [ ] Pod restart counts
  - [ ] Failed health checks
- [ ] Enable Container Insights
- [ ] Configure log retention policies

### Cost Management
- [ ] Set up AWS Cost Explorer
- [ ] Create budget alerts
- [ ] Review actual vs estimated costs
- [ ] Tag all resources properly
- [ ] Enable cost allocation tags

### Backup and DR
- [ ] Configure MongoDB backup strategy
- [ ] Test backup restoration
- [ ] Document disaster recovery procedures
- [ ] Setup cross-region replication (optional)

### Documentation
- [ ] Update REACT_APP_API_URL secret with ALB URL
- [ ] Document ALB DNS name
- [ ] Update team wiki/confluence
- [ ] Share access credentials securely
- [ ] Document troubleshooting steps

---

## Ongoing Maintenance Checklist

### Daily
- [ ] Check pod status
- [ ] Review application logs
- [ ] Monitor error rates
- [ ] Check resource usage

### Weekly
- [ ] Review CloudWatch metrics
- [ ] Check for security vulnerabilities
- [ ] Review cost reports
- [ ] Update dependencies if needed

### Monthly
- [ ] Review and update autoscaling policies
- [ ] Check for EKS version updates
- [ ] Review backup retention
- [ ] Cost optimization review
- [ ] Security audit

### Quarterly
- [ ] Disaster recovery drill
- [ ] Performance testing
- [ ] Architecture review
- [ ] Update documentation

---

## Troubleshooting Checklist

### Pods Not Starting
- [ ] Check pod status (`kubectl get pods -n credit-card-system`)
- [ ] Describe pod (`kubectl describe pod <pod-name> -n credit-card-system`)
- [ ] Check pod logs (`kubectl logs <pod-name> -n credit-card-system`)
- [ ] Verify image exists in ECR
- [ ] Check image pull permissions
- [ ] Verify secrets are created
- [ ] Check resource limits

### Cannot Access Application
- [ ] Verify ALB is provisioned
- [ ] Check ingress status
- [ ] Review ALB controller logs
- [ ] Verify security group rules
- [ ] Check target group health
- [ ] Test services directly (port-forward)
- [ ] Review DNS propagation

### High Costs
- [ ] Check instance types
- [ ] Review NAT gateway usage
- [ ] Analyze data transfer costs
- [ ] Check unused resources
- [ ] Review EBS volume usage
- [ ] Consider reserved instances

### Performance Issues
- [ ] Check HPA configuration
- [ ] Review resource requests/limits
- [ ] Analyze slow queries
- [ ] Check network latency
- [ ] Review application logs
- [ ] Consider vertical scaling

---

## Cleanup Checklist

### Delete Application Only
- [ ] Delete namespace
  ```bash
  kubectl delete namespace credit-card-system
  ```
- [ ] Verify all resources deleted
- [ ] Check for orphaned load balancers

### Complete Cleanup
- [ ] Delete Kubernetes resources
- [ ] Run terraform destroy
- [ ] Delete S3 bucket
- [ ] Delete DynamoDB table
- [ ] Delete CloudWatch log groups
- [ ] Remove ECR images
- [ ] Delete ECR repositories
- [ ] Remove IAM roles (if unused)
- [ ] Verify all resources deleted in AWS Console
- [ ] Check for any remaining costs

---

## Success Criteria

Deployment is successful when:
- ✅ All pods are in Running state
- ✅ All health checks pass
- ✅ Application is accessible via ALB URL
- ✅ All features work correctly
- ✅ No errors in logs
- ✅ Autoscaling works as expected
- ✅ CI/CD pipelines run successfully
- ✅ Monitoring is configured
- ✅ Costs are within budget

---

## Contact and Support

- **Documentation**: See DEPLOYMENT.md and QUICKSTART_AWS.md
- **Issues**: https://github.com/Vinod7723/Credit_card_recommendation/issues
- **AWS Support**: https://console.aws.amazon.com/support/

---

## Notes

**Date Deployed**: ______3_________

**Deployed By**: _______________

**ALB URL**: _______________

**Cluster Name**: credit-card-system-production

**Region**: us-east-1

**Account ID**: _______________

**Notes**:
_______________________________________________
_______________________________________________
_______________________________________________
