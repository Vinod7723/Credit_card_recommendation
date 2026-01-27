# Credit Card Recommendation System - Architecture

> **Author:** Vinod Reddy Billipalli
> **Infrastructure:** AWS EKS, Terraform, Docker, Kubernetes
> **Date:** 2026-01-26

## Table of Contents
1. [System Overview](#system-overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Component Details](#component-details)
4. [Network Architecture](#network-architecture)
5. [Security Architecture](#security-architecture)
6. [Monitoring & Observability](#monitoring--observability)
7. [CI/CD Pipeline](#cicd-pipeline)
8. [Cost Optimization](#cost-optimization)

---

## System Overview

The Credit Card Recommendation System is an AI-powered web application that:
- **Frontend**: React.js SPA served via Nginx
- **Backend**: Flask API with OpenAI integration
- **Database**: MongoDB for data persistence
- **Infrastructure**: AWS EKS (Kubernetes) with auto-scaling
- **Deployment**: Automated CI/CD via GitHub Actions

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            END USERS                                     │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 │ HTTPS/HTTP
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       AWS CLOUD (us-east-1)                              │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │                    Application Load Balancer                    │    │
│  │              (Internet-facing, Multi-AZ)                        │    │
│  └───────────────┬────────────────────────────┬───────────────────┘    │
│                  │                             │                         │
│                  │ Path: /*                    │ Path: /api/*            │
│                  ▼                             ▼                         │
│  ┌──────────────────────────────┐  ┌──────────────────────────────┐   │
│  │    VPC: 10.0.0.0/16          │  │    VPC: 10.0.0.0/16          │   │
│  │  ┌────────────────────────┐  │  │  ┌────────────────────────┐  │   │
│  │  │  Availability Zone A   │  │  │  │  Availability Zone A   │  │   │
│  │  │                        │  │  │  │                        │  │   │
│  │  │  ┌──────────────────┐  │  │  │  │  ┌──────────────────┐  │  │   │
│  │  │  │  Frontend Pod    │  │  │  │  │  │  Backend Pod     │  │  │   │
│  │  │  │  (React/Nginx)   │  │  │  │  │  │  (Flask/Python)  │  │  │   │
│  │  │  │  Port: 80        │  │  │  │  │  │  Port: 5001      │  │  │   │
│  │  │  └──────────────────┘  │  │  │  │  └──────────────────┘  │  │   │
│  │  │                        │  │  │  │          │              │  │   │
│  │  └────────────────────────┘  │  │  └──────────┼──────────────┘  │   │
│  │                              │  │             │                  │   │
│  │  ┌────────────────────────┐  │  │  ┌──────────▼──────────────┐  │   │
│  │  │  Availability Zone B   │  │  │  │  Availability Zone B   │  │   │
│  │  │                        │  │  │  │                        │  │   │
│  │  │  ┌──────────────────┐  │  │  │  │  ┌──────────────────┐  │  │   │
│  │  │  │  Frontend Pod    │  │  │  │  │  │  Backend Pod     │  │  │   │
│  │  │  │  (Replica)       │  │  │  │  │  │  (Replica)       │  │  │   │
│  │  │  └──────────────────┘  │  │  │  │  └──────────────────┘  │  │   │
│  │  │                        │  │  │  │          │              │  │   │
│  │  └────────────────────────┘  │  │  └──────────┼──────────────┘  │   │
│  │                              │  │             │                  │   │
│  │  ┌────────────────────────┐  │  │  ┌──────────▼──────────────┐  │   │
│  │  │  Availability Zone C   │  │  │  │  Availability Zone C   │  │   │
│  │  │                        │  │  │  │                        │  │   │
│  │  │  ┌──────────────────┐  │  │  │  │  ┌──────────────────┐  │  │   │
│  │  │  │  Frontend Pod    │  │  │  │  │  │  Backend Pod     │  │  │   │
│  │  │  │  (Replica)       │  │  │  │  │  │  (Replica)       │  │  │   │
│  │  │  └──────────────────┘  │  │  │  │  └──────────────────┘  │  │   │
│  │  │                        │  │  │  │          │              │  │   │
│  │  └────────────────────────┘  │  │  └──────────┼──────────────┘  │   │
│  │                              │  │             │                  │   │
│  │  EKS Cluster Namespace:      │  │             │                  │   │
│  │  "credit-card-system"        │  │  ┌──────────▼──────────────┐  │   │
│  │                              │  │  │   MongoDB StatefulSet   │  │   │
│  │  HPA: 3-10 replicas          │  │  │   (Persistent Storage)  │  │   │
│  │  Auto-scaling based on       │  │  │   Port: 27017           │  │   │
│  │  CPU (70%) & Memory (80%)    │  │  │   Volume: 20GB EBS      │  │   │
│  │                              │  │  └─────────────────────────┘  │   │
│  └──────────────────────────────┘  └──────────────────────────────┘   │
│                                                                          │
│  ┌───────────────────────────────────────────────────────────────┐    │
│  │              Amazon EKS Control Plane (Managed)                │    │
│  │              - API Server                                       │    │
│  │              - Scheduler                                        │    │
│  │              - Controller Manager                               │    │
│  └───────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌───────────────────────────────────────────────────────────────┐    │
│  │                  EKS Worker Node Group                          │    │
│  │                  - Instance Type: t3.medium                     │    │
│  │                  - Min: 2, Max: 10, Desired: 3                  │    │
│  │                  - Auto Scaling Group                           │    │
│  └───────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌───────────────────────────────────────────────────────────────┐    │
│  │              Amazon ECR (Container Registry)                    │    │
│  │              - vinod-credit-card-backend-production             │    │
│  │              - vinod-credit-card-frontend-production            │    │
│  └───────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌───────────────────────────────────────────────────────────────┐    │
│  │                   CloudWatch Monitoring                         │    │
│  │              - Dashboard: VinodCreditCardSystem                 │    │
│  │              - Alarms: CPU, 5XX Errors, Response Time           │    │
│  │              - Container Insights for EKS                       │    │
│  └───────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌───────────────────────────────────────────────────────────────┐    │
│  │                  Amazon SNS (Alerting)                          │    │
│  │              - Topic: vinod-credit-card-alerts                  │    │
│  │              - Email notifications to: [your-email]             │    │
│  └───────────────────────────────────────────────────────────────┘    │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                          CI/CD Pipeline                                  │
│                                                                           │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐           │
│  │   GitHub     │────▶│GitHub Actions│────▶│   AWS EKS    │           │
│  │  Repository  │     │   Workflow   │     │  Deployment  │           │
│  └──────────────┘     └──────────────┘     └──────────────┘           │
│                                                                           │
│  Triggers: Push to main/develop                                         │
│  Steps: Lint → Test → Build → Push ECR → Deploy EKS                    │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                    Infrastructure as Code                                │
│                                                                           │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐           │
│  │   Terraform  │────▶│  AWS API     │────▶│    AWS       │           │
│  │   Templates  │     │   Calls      │     │  Resources   │           │
│  └──────────────┘     └──────────────┘     └──────────────┘           │
│                                                                           │
│  State: S3 Backend + DynamoDB Lock                                      │
│  Modules: VPC, EKS, ECR, IAM                                            │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Component Details

### 1. Frontend Service
- **Technology**: React.js 18+ with Material-UI
- **Web Server**: Nginx 1.25
- **Container**: Multi-stage Docker build
- **Scaling**: HPA 3-10 replicas
- **Resource Limits**:
  - CPU: 100m request, 500m limit
  - Memory: 128Mi request, 512Mi limit

### 2. Backend Service
- **Technology**: Flask (Python 3.12)
- **WSGI Server**: Gunicorn (4 workers)
- **AI Integration**: OpenAI GPT API
- **OCR**: Tesseract for document processing
- **Scaling**: HPA 3-10 replicas
- **Resource Limits**:
  - CPU: 250m request, 1000m limit
  - Memory: 512Mi request, 2Gi limit

### 3. Database Service
- **Technology**: MongoDB 6.0
- **Storage**: 20GB GP3 EBS volume
- **Persistence**: PersistentVolumeClaim
- **Backup**: (Manual/scheduled snapshots)

### 4. Load Balancer
- **Type**: AWS Application Load Balancer (ALB)
- **Ingress Controller**: AWS Load Balancer Controller
- **Routing**:
  - `/` → Frontend Service
  - `/api/*` → Backend Service
- **Health Checks**: Every 30s

---

## Network Architecture

### VPC Configuration
- **CIDR**: 10.0.0.0/16
- **Subnets**:
  - **Public Subnets** (3 AZs):
    - 10.0.0.0/20 (us-east-1a)
    - 10.0.16.0/20 (us-east-1b)
    - 10.0.32.0/20 (us-east-1c)
  - **Private Subnets** (3 AZs):
    - 10.0.48.0/20 (us-east-1a)
    - 10.0.64.0/20 (us-east-1b)
    - 10.0.80.0/20 (us-east-1c)

### Gateway Configuration
- **Internet Gateway**: 1 for public subnets
- **NAT Gateways**: 3 (one per AZ for high availability)
- **Elastic IPs**: 3 (one per NAT Gateway)

### Security Groups
- **ALB Security Group**:
  - Inbound: 80 (HTTP), 443 (HTTPS) from 0.0.0.0/0
- **EKS Node Security Group**:
  - Inbound: From ALB security group
  - Inbound: From EKS control plane
- **Pod Security Group**:
  - Inbound: From ALB
  - Outbound: All traffic

---

## Security Architecture

### 1. Network Security
- ✅ Private subnets for EKS worker nodes
- ✅ NAT Gateways for outbound internet access
- ✅ Security groups with least privilege
- ✅ Network ACLs (default VPC ACLs)

### 2. IAM Security
- ✅ IRSA (IAM Roles for Service Accounts)
- ✅ ALB Controller IAM role with minimal permissions
- ✅ EKS node IAM role
- ✅ Separate IAM users for CI/CD

### 3. Secrets Management
- ✅ Kubernetes Secrets (base64 encoded)
- ✅ GitHub Secrets for CI/CD
- ✅ Environment variable injection
- 🔄 (Future) AWS Secrets Manager integration

### 4. Container Security
- ✅ Security scanning with Trivy
- ✅ Non-root containers
- ✅ Read-only root filesystem (where possible)
- ✅ Image pull policy: Always (latest security patches)

### 5. Cluster Security
- ✅ EKS cluster endpoint: Public (can be private)
- ✅ Cluster logging enabled
- ✅ RBAC enabled
- ✅ Pod Security Standards

---

## Monitoring & Observability

### CloudWatch Dashboard
**Name**: `VinodCreditCardSystem`

**Metrics Tracked**:
1. EKS cluster node count & failures
2. ALB request count & response time
3. HTTP status codes (2xx, 4xx, 5xx)
4. Target health (healthy/unhealthy hosts)
5. EC2 CPU utilization
6. Network traffic (in/out)
7. EKS cluster logs
8. ALB connection metrics

### CloudWatch Alarms
1. **High CPU Utilization**: >80% for 10 minutes
2. **Unhealthy Targets**: ≥1 for 2 minutes
3. **High 5XX Errors**: >10 in 5 minutes
4. **High Response Time**: >2s for 10 minutes
5. **EKS Node Failures**: ≥1 failed node

### Notifications
- **SNS Topic**: `vinod-credit-card-alerts`
- **Protocol**: Email
- **Actions**: Alert on alarm state change

### Container Insights
- ✅ Pod-level metrics
- ✅ Node-level metrics
- ✅ Cluster-level metrics
- ✅ Performance monitoring

---

## CI/CD Pipeline

### GitHub Actions Workflows

#### 1. Backend Pipeline (`backend-deploy.yml`)
```
Trigger: Push to main/develop
├── Lint & Test
│   ├── flake8 (syntax check)
│   ├── black (formatting)
│   └── pytest (unit tests)
├── Build & Push
│   ├── Build Docker image
│   ├── Push to ECR
│   └── Trivy security scan
└── Deploy to EKS
    ├── Update kubeconfig
    ├── Update K8s manifests
    ├── Apply manifests
    └── Verify deployment
```

#### 2. Frontend Pipeline (`frontend-deploy.yml`)
```
Trigger: Push to main/develop
├── Lint & Test
│   ├── ESLint (code quality)
│   ├── npm audit (security)
│   └── Build test
├── Build & Push
│   ├── Build Docker image
│   ├── Push to ECR
│   └── Trivy security scan
└── Deploy to EKS
    ├── Update kubeconfig
    ├── Update K8s manifests
    ├── Apply manifests
    └── Verify deployment
```

#### 3. Terraform Pipeline (`terraform-deploy.yml`)
```
Trigger: Push/PR to main
├── Validate
│   ├── terraform fmt -check
│   └── terraform validate
├── Plan
│   ├── terraform plan
│   └── Comment on PR
└── Apply (main only)
    ├── terraform apply
    └── Output infrastructure details
```

---

## Cost Optimization

### Current Configuration Costs (Estimated Monthly)

| Service | Configuration | Estimated Cost |
|---------|--------------|----------------|
| EKS Cluster | 1 cluster | $73 |
| EC2 (t3.medium) | 3 instances | $90 |
| EBS Volumes | 50GB GP3 | $5 |
| ALB | 1 load balancer | $20 |
| NAT Gateways | 3 gateways | $100 |
| ECR Storage | ~5GB | $0.50 |
| CloudWatch | Logs + Metrics | $10 |
| Data Transfer | ~100GB | $10 |
| **TOTAL** | | **~$308/month** |

### Cost Optimization Strategies

1. **NAT Gateway Optimization**
   - Current: 3 NAT Gateways ($100/month)
   - Option: Use 1 NAT Gateway (saves $67/month)
   - Trade-off: Reduced high availability

2. **Instance Right-Sizing**
   - Current: t3.medium
   - Option: t3.small for development (saves 50%)
   - Monitor: CPU/Memory utilization

3. **EKS Fargate** (Alternative)
   - Serverless compute
   - Pay only for pod resources
   - No EC2 management

4. **Reserved Instances**
   - 1-year commitment: 30-40% savings
   - 3-year commitment: 50-60% savings

5. **Auto-Scaling**
   - Scale down to 2 nodes during off-hours
   - Use cluster autoscaler
   - Potential savings: 30-50% during low traffic

6. **CloudWatch Log Retention**
   - Set log retention to 7-14 days
   - Archive old logs to S3
   - Use S3 Intelligent-Tiering

---

## Deployment Flow

```
Local Development
      │
      ├── Code changes
      ├── Git commit
      └── Git push
      │
      ▼
GitHub Repository
      │
      ├── Webhook triggers
      └── GitHub Actions
      │
      ▼
CI/CD Pipeline
      │
      ├── Run tests
      ├── Build Docker images
      ├── Security scan
      └── Push to ECR
      │
      ▼
AWS ECR
      │
      └── Container images stored
      │
      ▼
EKS Deployment
      │
      ├── Pull images from ECR
      ├── Update pods (rolling update)
      └── Health check verification
      │
      ▼
Production Live! 🚀
```

---

## Infrastructure State Management

### Terraform State
- **Backend**: S3 bucket
- **Locking**: DynamoDB table
- **Encryption**: AES256 (server-side)
- **Versioning**: Enabled
- **Bucket Name**: `vinod-credit-card-terraform-state-{account-id}`

---

## Disaster Recovery

### Backup Strategy
1. **Database**: Manual MongoDB dumps (daily recommended)
2. **EBS Snapshots**: Automated via AWS Backup
3. **Container Images**: Retained in ECR (last 10 versions)
4. **Infrastructure**: Terraform state in S3 (versioned)

### Recovery Time Objective (RTO)
- **Infrastructure**: ~20 minutes (Terraform apply)
- **Application**: ~5 minutes (K8s deployment)
- **Total RTO**: ~25 minutes

### Recovery Point Objective (RPO)
- **Application**: 0 (stateless, no data loss)
- **Database**: Daily backups (24-hour RPO)

---

## Scaling Strategy

### Horizontal Scaling
- **HPA Metrics**:
  - CPU: 70% threshold
  - Memory: 80% threshold
- **Min Replicas**: 3
- **Max Replicas**: 10

### Vertical Scaling
- Adjust resource requests/limits
- Change instance types

### Cluster Scaling
- Use Cluster Autoscaler
- Scale EC2 instances based on pod demands

---

## Future Enhancements

1. **Service Mesh**: Implement Istio for advanced traffic management
2. **GitOps**: Adopt ArgoCD for declarative deployments
3. **Multi-Region**: Deploy to multiple regions for global availability
4. **CDN**: Add CloudFront for static asset distribution
5. **WAF**: Implement AWS WAF for security
6. **Secrets Manager**: Migrate to AWS Secrets Manager
7. **Database**: Upgrade to Amazon DocumentDB (managed MongoDB)
8. **Observability**: Add Prometheus + Grafana

---

## Useful Links

- **CloudWatch Dashboard**: `https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=VinodCreditCardSystem`
- **EKS Console**: `https://console.aws.amazon.com/eks/home?region=us-east-1#/clusters/vinod-credit-card-production`
- **ECR Console**: `https://console.aws.amazon.com/ecr/repositories?region=us-east-1`
- **Terraform State**: `s3://vinod-credit-card-terraform-state-{account-id}/prod/terraform.tfstate`

---

**Created by Vinod Reddy Billipalli**
*Demonstrating DevSecOps, FinOps, and Cloud Engineering expertise*
