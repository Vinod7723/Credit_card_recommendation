# Main Terraform configuration for Credit Card Recommendation System
# AWS EKS Infrastructure

# Provider configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "CreditCardRecommendation"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Vinod Reddy Billipalli"
    }
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  azs          = var.availability_zones
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  project_name        = var.project_name
  environment         = var.environment
  cluster_version     = var.cluster_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  node_group_min_size = var.node_group_min_size
  node_group_max_size = var.node_group_max_size
  node_group_desired  = var.node_group_desired
  node_instance_types = var.node_instance_types
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  repositories = ["credit-card-backend", "credit-card-frontend"]
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  project_name      = var.project_name
  environment       = var.environment
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
}

# Install AWS Load Balancer Controller using null_resource and kubectl
resource "null_resource" "install_alb_controller" {
  provisioner "local-exec" {
    command = <<-EOT
      # Update kubeconfig
      aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}

      # Add helm repo
      helm repo add eks https://aws.github.io/eks-charts
      helm repo update

      # Install AWS Load Balancer Controller
      helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName=${module.eks.cluster_name} \
        --set serviceAccount.create=true \
        --set serviceAccount.name=aws-load-balancer-controller \
        --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${module.iam.alb_controller_role_arn}

      # Install Metrics Server
      helm upgrade --install metrics-server \
        https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml \
        -n kube-system || kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    EOT
  }

  depends_on = [module.eks, module.iam]
}
