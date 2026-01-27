# 🚀 START HERE - Quick Deployment Guide

> **Your Credit Card Recommendation System is ready to deploy to AWS!**

---

## ⚡ 3-Minute Quick Start

### Step 1: Prerequisites Check (1 minute)

```bash
# Check if you have everything installed
aws --version          # AWS CLI
terraform --version    # Terraform
kubectl version        # kubectl
helm version          # Helm
docker --version      # Docker

# Configure AWS (if not done)
aws configure
```

### Step 2: Deploy to AWS (1 minute to start, 20 minutes to complete)

```bash
# Run the automated deployment script
./deploy-to-aws.sh
```

**Enter when prompted:**
- Your OpenAI API Key

**What it does:**
1. ✅ Validates prerequisites
2. ✅ Creates Terraform backend (S3 + DynamoDB)
3. ✅ Deploys AWS infrastructure (VPC, EKS, ECR)
4. ✅ Builds Docker images
5. ✅ Pushes images to ECR
6. ✅ Deploys application to Kubernetes
7. ✅ Provides your live application URL

### Step 3: Setup Monitoring (30 seconds)

```bash
# After deployment completes
./setup-monitoring.sh
```

**Enter when prompted:**
- Your email for alerts

---

## 📋 Deployment Checklist

- [ ] AWS credentials configured (`aws configure`)
- [ ] OpenAI API key ready
- [ ] All prerequisites installed
- [ ] Run `./deploy-to-aws.sh`
- [ ] Wait 20 minutes for deployment
- [ ] Copy the application URL
- [ ] Run `./setup-monitoring.sh`
- [ ] Confirm SNS email subscription
- [ ] Setup GitHub Actions (optional for CI/CD)

---

## 🎯 What You Get

After deployment, you'll have:

✅ **Live Application** at `http://<alb-url>`
✅ **EKS Cluster** with 3 worker nodes
✅ **Auto-scaling** backend and frontend (3-10 replicas)
✅ **MongoDB** with persistent storage
✅ **Load Balancer** for high availability
✅ **CloudWatch** monitoring dashboard
✅ **Email Alerts** for issues
✅ **CI/CD Pipelines** ready to use

---

## 📊 Resources Created

| Resource | Quantity | Details |
|----------|----------|---------|
| VPC | 1 | 10.0.0.0/16 |
| Subnets | 6 | 3 public + 3 private |
| NAT Gateways | 3 | One per AZ |
| EKS Cluster | 1 | Kubernetes 1.28 |
| Worker Nodes | 3 | t3.medium instances |
| ECR Repositories | 2 | Backend + Frontend |
| Load Balancer | 1 | Application LB |
| CloudWatch Dashboard | 1 | Full metrics |
| CloudWatch Alarms | 5 | Health monitoring |

**Estimated Cost:** ~$308/month

---

## 🔍 After Deployment

### Check Application Status

```bash
# View all resources
kubectl get all -n credit-card-system

# View application URL
kubectl get ingress credit-card-ingress -n credit-card-system

# View logs
kubectl logs -f deployment/backend -n credit-card-system
```

### Access Monitoring

1. **CloudWatch Dashboard**:
   - Go to: AWS Console → CloudWatch → Dashboards → `VinodCreditCardSystem`

2. **Check Email**:
   - Confirm SNS subscription for alerts

### Setup CI/CD (Optional)

See [GITHUB_SETUP.md](./GITHUB_SETUP.md) for GitHub Actions configuration.

---

## 📚 Full Documentation

| Document | Purpose |
|----------|---------|
| [README.md](./README.md) | Project overview and quick start |
| [DEPLOY_LIVE.md](./DEPLOY_LIVE.md) | Complete step-by-step deployment guide |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Detailed architecture documentation |
| [GITHUB_SETUP.md](./GITHUB_SETUP.md) | CI/CD pipeline setup |

---

## 🆘 Need Help?

### Common Issues

**Q: Deployment script fails?**
- Check AWS credentials: `aws sts get-caller-identity`
- Ensure sufficient IAM permissions
- Check disk space: `df -h`

**Q: Can't access application?**
- Wait 5 minutes for ALB to provision
- Check ingress: `kubectl get ingress -n credit-card-system`

**Q: Pods not starting?**
- Check logs: `kubectl logs <pod-name> -n credit-card-system`
- Verify images in ECR

### Full Troubleshooting Guide
See [DEPLOY_LIVE.md - Troubleshooting](./DEPLOY_LIVE.md#-troubleshooting)

---

## 🧹 Cleanup (When Done)

```bash
# Delete everything
kubectl delete namespace credit-card-system
cd terraform
terraform destroy -auto-approve
```

---

## ⏱️ Time Estimates

| Task | Time |
|------|------|
| Prerequisites setup | 5-10 minutes |
| Run deployment script | 20-25 minutes |
| Setup monitoring | 2-3 minutes |
| Setup CI/CD | 5 minutes |
| **Total** | **~35 minutes** |

---

## 🎉 Ready to Deploy?

```bash
# Just run this command and follow the prompts!
./deploy-to-aws.sh
```

**Your enterprise-grade AWS deployment starts now!** 🚀

---

*Created by Vinod Reddy Billipalli*
*Demonstrating DevSecOps and Cloud Engineering Excellence*
