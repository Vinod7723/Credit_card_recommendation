# Terraform Variables for Vinod's Credit Card Recommendation System
# AWS EKS Production Deployment

aws_region = "us-east-1"

project_name = "vinod-credit-card"

environment = "production"

vpc_cidr = "10.0.0.0/16"

availability_zones = [
  "us-east-1a",
  "us-east-1b",
  "us-east-1c"
]

cluster_version = "1.30"

node_group_min_size = 2

node_group_max_size = 10

node_group_desired = 3

node_instance_types = [
  "t3.small"
]

enable_monitoring = true

enable_logging = true

tags = {
  Owner       = "Vinod Reddy Billipalli"
  ManagedBy   = "Terraform"
  Project     = "Credit Card Recommendation System"
  Environment = "Production"
  DeployedBy  = "vinod"
}
