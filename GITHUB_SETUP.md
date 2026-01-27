# GitHub Actions Setup Guide

## Required GitHub Secrets

To enable CI/CD pipelines, you need to configure the following secrets in your GitHub repository:

### Navigation Path
1. Go to your GitHub repository
2. Click **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret**

### Required Secrets

| Secret Name | Description | How to Get |
|------------|-------------|------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key | Run: `aws configure get aws_access_key_id` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | Run: `aws configure get aws_secret_access_key` |
| `AWS_ACCOUNT_ID` | Your AWS Account ID | Run: `aws sts get-caller-identity --query Account --output text` |
| `OPENAI_API_KEY` | OpenAI API Key | Get from https://platform.openai.com/api-keys |

## Step-by-Step Configuration

### 1. Get AWS Credentials

```bash
# Get your AWS Account ID
aws sts get-caller-identity --query Account --output text

# Get Access Key ID (from AWS IAM Console or aws configure)
aws configure get aws_access_key_id

# Get Secret Access Key (from AWS IAM Console or aws configure)
aws configure get aws_secret_access_key
```

### 2. Add Secrets to GitHub

For each secret:
1. Click **New repository secret**
2. Enter the **Name** (e.g., `AWS_ACCESS_KEY_ID`)
3. Paste the **Value**
4. Click **Add secret**

### 3. Verify Secrets

After adding all secrets, you should see:
- ✅ AWS_ACCESS_KEY_ID
- ✅ AWS_SECRET_ACCESS_KEY
- ✅ AWS_ACCOUNT_ID
- ✅ OPENAI_API_KEY

## Workflows Configured

### 1. Backend CI/CD (`backend-deploy.yml`)
- **Triggers**: Push to `main` or `develop` branches
- **Actions**:
  - Lint Python code with flake8 and black
  - Run tests
  - Build Docker image
  - Push to ECR
  - Security scan with Trivy
  - Deploy to EKS

### 2. Frontend CI/CD (`frontend-deploy.yml`)
- **Triggers**: Push to `main` or `develop` branches
- **Actions**:
  - Lint JavaScript code
  - Build React application
  - Build Docker image
  - Push to ECR
  - Deploy to EKS

### 3. Terraform CI/CD (`terraform-deploy.yml`)
- **Triggers**: Push to `main` or PR to `main`
- **Actions**:
  - Validate Terraform
  - Plan infrastructure changes
  - Apply changes (on main branch)
  - Comment plan on PRs

## Manual Workflow Triggers

All workflows support manual triggering:

1. Go to **Actions** tab
2. Select the workflow
3. Click **Run workflow**
4. Choose branch and click **Run workflow**

## Best Practices

1. **Never commit secrets to git**
2. **Use separate AWS IAM users for CI/CD** with minimal permissions
3. **Rotate secrets regularly** (every 90 days)
4. **Enable branch protection** for `main` branch
5. **Require PR reviews** before merging

## Troubleshooting

### Workflow fails with "AWS credentials not configured"
- Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are set correctly
- Check IAM user has required permissions

### ECR push fails
- Ensure AWS credentials have `ecr:*` permissions
- Verify ECR repository exists

### EKS deployment fails
- Ensure `EKS_CLUSTER_NAME` matches your actual cluster name
- Verify IAM user has `eks:DescribeCluster` permission
- Check cluster is in the correct region

## Required IAM Permissions

Your CI/CD IAM user should have these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:*",
        "eks:DescribeCluster",
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

## Next Steps

After configuring secrets:
1. Push code to trigger workflows
2. Monitor workflow execution in **Actions** tab
3. Check deployment status in AWS Console
4. Access application via Load Balancer URL
