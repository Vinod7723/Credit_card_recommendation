#!/bin/bash

###############################################################################
# CloudWatch Monitoring and Alerting Setup
# Author: Vinod Reddy Billipalli
# Description: Sets up CloudWatch dashboards and alarms for EKS cluster
###############################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         CloudWatch Monitoring and Alerting Setup              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

###############################################################################
# Get Configuration
###############################################################################
AWS_REGION=$(aws configure get region || echo "us-east-1")
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
CLUSTER_NAME="vinod-credit-card-production"

log_info "AWS Region: $AWS_REGION"
log_info "AWS Account ID: $AWS_ACCOUNT_ID"
log_info "Cluster Name: $CLUSTER_NAME"

# Get email for alerts
echo ""
log_warning "Email address for CloudWatch alerts:"
read -p "Enter your email: " ALERT_EMAIL

if [ -z "$ALERT_EMAIL" ]; then
    log_error "Email is required for alerts"
    exit 1
fi

###############################################################################
# Create SNS Topic for Alerts
###############################################################################
echo ""
log_info "Creating SNS topic for alerts..."

TOPIC_NAME="vinod-credit-card-alerts"
TOPIC_ARN=$(aws sns create-topic \
    --name "${TOPIC_NAME}" \
    --region "${AWS_REGION}" \
    --output text --query 'TopicArn' 2>/dev/null || \
    aws sns list-topics --region "${AWS_REGION}" --output text --query "Topics[?contains(@, '${TOPIC_NAME}')]")

log_success "SNS Topic ARN: ${TOPIC_ARN}"

# Subscribe email to SNS topic
log_info "Subscribing email to SNS topic..."
aws sns subscribe \
    --topic-arn "${TOPIC_ARN}" \
    --protocol email \
    --notification-endpoint "${ALERT_EMAIL}" \
    --region "${AWS_REGION}" || true

log_warning "Check your email (${ALERT_EMAIL}) and confirm the SNS subscription"

###############################################################################
# Create CloudWatch Dashboard
###############################################################################
echo ""
log_info "Creating CloudWatch dashboard..."

DASHBOARD_NAME="VinodCreditCardSystem"

DASHBOARD_BODY=$(cat <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/EKS", "cluster_failed_node_count", {"stat": "Average"}],
          [".", "cluster_node_count", {"stat": "Average"}]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${AWS_REGION}",
        "title": "EKS Cluster Nodes",
        "period": 300,
        "yAxis": {
          "left": {
            "min": 0
          }
        }
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ApplicationELB", "TargetResponseTime", {"stat": "Average"}],
          [".", "RequestCount", {"stat": "Sum", "yAxis": "right"}]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${AWS_REGION}",
        "title": "Application Load Balancer Metrics",
        "period": 300,
        "yAxis": {
          "left": {
            "label": "Response Time (ms)",
            "min": 0
          },
          "right": {
            "label": "Request Count"
          }
        }
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", {"stat": "Sum", "color": "#2ca02c"}],
          [".", "HTTPCode_Target_4XX_Count", {"stat": "Sum", "color": "#ff7f0e"}],
          [".", "HTTPCode_Target_5XX_Count", {"stat": "Sum", "color": "#d62728"}]
        ],
        "view": "timeSeries",
        "stacked": true,
        "region": "${AWS_REGION}",
        "title": "HTTP Response Codes",
        "period": 300,
        "yAxis": {
          "left": {
            "min": 0
          }
        }
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ApplicationELB", "UnHealthyHostCount", {"stat": "Maximum", "color": "#d62728"}],
          [".", "HealthyHostCount", {"stat": "Maximum", "color": "#2ca02c"}]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${AWS_REGION}",
        "title": "Target Health",
        "period": 60,
        "yAxis": {
          "left": {
            "min": 0
          }
        }
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/EC2", "CPUUtilization", {"stat": "Average"}]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${AWS_REGION}",
        "title": "EC2 CPU Utilization",
        "period": 300,
        "yAxis": {
          "left": {
            "min": 0,
            "max": 100
          }
        }
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/EC2", "NetworkIn", {"stat": "Sum"}],
          [".", "NetworkOut", {"stat": "Sum"}]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${AWS_REGION}",
        "title": "Network Traffic",
        "period": 300,
        "yAxis": {
          "left": {
            "min": 0
          }
        }
      }
    },
    {
      "type": "log",
      "properties": {
        "query": "SOURCE '/aws/eks/${CLUSTER_NAME}/cluster'\n| fields @timestamp, @message\n| sort @timestamp desc\n| limit 20",
        "region": "${AWS_REGION}",
        "title": "Recent EKS Cluster Logs",
        "stacked": false
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ApplicationELB", "ActiveConnectionCount", {"stat": "Sum"}],
          [".", "NewConnectionCount", {"stat": "Sum"}]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${AWS_REGION}",
        "title": "ALB Connections",
        "period": 60
      }
    }
  ]
}
EOF
)

aws cloudwatch put-dashboard \
    --dashboard-name "${DASHBOARD_NAME}" \
    --dashboard-body "${DASHBOARD_BODY}" \
    --region "${AWS_REGION}"

log_success "Dashboard created: ${DASHBOARD_NAME}"

###############################################################################
# Create CloudWatch Alarms
###############################################################################
echo ""
log_info "Creating CloudWatch alarms..."

# Alarm 1: High CPU Utilization
log_info "Creating alarm: High CPU Utilization..."
aws cloudwatch put-metric-alarm \
    --alarm-name "vinod-credit-card-high-cpu" \
    --alarm-description "Alert when CPU utilization is high" \
    --actions-enabled \
    --alarm-actions "${TOPIC_ARN}" \
    --metric-name CPUUtilization \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --evaluation-periods 2 \
    --threshold 80.0 \
    --comparison-operator GreaterThanThreshold \
    --region "${AWS_REGION}"

log_success "Alarm created: High CPU Utilization (>80% for 10 minutes)"

# Alarm 2: Unhealthy Targets
log_info "Creating alarm: Unhealthy Targets..."
aws cloudwatch put-metric-alarm \
    --alarm-name "vinod-credit-card-unhealthy-targets" \
    --alarm-description "Alert when targets are unhealthy" \
    --actions-enabled \
    --alarm-actions "${TOPIC_ARN}" \
    --metric-name UnHealthyHostCount \
    --namespace AWS/ApplicationELB \
    --statistic Maximum \
    --period 60 \
    --evaluation-periods 2 \
    --threshold 1.0 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --region "${AWS_REGION}"

log_success "Alarm created: Unhealthy Targets (>=1 for 2 minutes)"

# Alarm 3: High 5XX Error Rate
log_info "Creating alarm: High 5XX Error Rate..."
aws cloudwatch put-metric-alarm \
    --alarm-name "vinod-credit-card-high-5xx-errors" \
    --alarm-description "Alert when 5XX error rate is high" \
    --actions-enabled \
    --alarm-actions "${TOPIC_ARN}" \
    --metric-name HTTPCode_Target_5XX_Count \
    --namespace AWS/ApplicationELB \
    --statistic Sum \
    --period 300 \
    --evaluation-periods 1 \
    --threshold 10.0 \
    --comparison-operator GreaterThanThreshold \
    --region "${AWS_REGION}"

log_success "Alarm created: High 5XX Errors (>10 in 5 minutes)"

# Alarm 4: High Response Time
log_info "Creating alarm: High Response Time..."
aws cloudwatch put-metric-alarm \
    --alarm-name "vinod-credit-card-high-response-time" \
    --alarm-description "Alert when response time is high" \
    --actions-enabled \
    --alarm-actions "${TOPIC_ARN}" \
    --metric-name TargetResponseTime \
    --namespace AWS/ApplicationELB \
    --statistic Average \
    --period 300 \
    --evaluation-periods 2 \
    --threshold 2.0 \
    --comparison-operator GreaterThanThreshold \
    --region "${AWS_REGION}"

log_success "Alarm created: High Response Time (>2s for 10 minutes)"

# Alarm 5: EKS Node Failures
log_info "Creating alarm: EKS Node Failures..."
aws cloudwatch put-metric-alarm \
    --alarm-name "vinod-credit-card-eks-node-failures" \
    --alarm-description "Alert when EKS nodes fail" \
    --actions-enabled \
    --alarm-actions "${TOPIC_ARN}" \
    --metric-name cluster_failed_node_count \
    --namespace AWS/EKS \
    --statistic Maximum \
    --period 60 \
    --evaluation-periods 1 \
    --threshold 1.0 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --region "${AWS_REGION}"

log_success "Alarm created: EKS Node Failures (>=1 failed node)"

###############################################################################
# Create Container Insights for EKS
###############################################################################
echo ""
log_info "Enabling Container Insights for EKS..."

# Check if cluster exists
if aws eks describe-cluster --name "${CLUSTER_NAME}" --region "${AWS_REGION}" &>/dev/null; then
    # Install CloudWatch agent via kubectl
    log_info "Installing CloudWatch Container Insights..."

    # Create namespace
    kubectl create namespace amazon-cloudwatch || true

    # Create service account
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cloudwatch-agent
  namespace: amazon-cloudwatch
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cloudwatch-agent-role
rules:
  - apiGroups: [""]
    resources: ["pods", "nodes", "endpoints"]
    verbs: ["list", "watch"]
  - apiGroups: ["apps"]
    resources: ["replicasets"]
    verbs: ["list", "watch"]
  - apiGroups: ["batch"]
    resources: ["jobs"]
    verbs: ["list", "watch"]
  - apiGroups: [""]
    resources: ["nodes/proxy"]
    verbs: ["get"]
  - apiGroups: [""]
    resources: ["nodes/stats", "configmaps", "events"]
    verbs: ["create", "get", "list", "watch"]
  - nonResourceURLs: ["/metrics"]
    verbs: ["get"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cloudwatch-agent-role-binding
subjects:
  - kind: ServiceAccount
    name: cloudwatch-agent
    namespace: amazon-cloudwatch
roleRef:
  kind: ClusterRole
  name: cloudwatch-agent-role
  apiGroup: rbac.authorization.k8s.io
EOF

    log_success "CloudWatch Container Insights configured"
else
    log_warning "EKS cluster not found. Container Insights will be set up after cluster deployment."
fi

###############################################################################
# Summary
###############################################################################
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              Monitoring Setup Complete                         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Dashboard:          ${DASHBOARD_NAME}"
echo "Dashboard URL:      https://console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#dashboards:name=${DASHBOARD_NAME}"
echo ""
echo "SNS Topic:          ${TOPIC_ARN}"
echo "Alert Email:        ${ALERT_EMAIL}"
echo ""
echo "Alarms Created:"
echo "  1. High CPU Utilization (>80%)"
echo "  2. Unhealthy Targets (>=1)"
echo "  3. High 5XX Errors (>10 in 5 min)"
echo "  4. High Response Time (>2s)"
echo "  5. EKS Node Failures (>=1)"
echo ""
log_warning "IMPORTANT: Check ${ALERT_EMAIL} and confirm SNS subscription!"
echo ""
log_success "Monitoring setup completed successfully! 🎉"
