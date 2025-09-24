# Electra Infrastructure as Code

This directory contains Terraform configuration for provisioning AWS infrastructure for the Electra secure digital voting system.

## Architecture Overview

The infrastructure includes:

- **VPC**: Multi-AZ virtual private cloud with public, private, and database subnets
- **EKS**: Managed Kubernetes cluster for application hosting
- **RDS**: Managed PostgreSQL database with automated backups
- **S3**: Object storage for media files and backups
- **IAM**: Service accounts and roles with least-privilege access
- **Secrets Manager**: Secure storage for application secrets
- **Security Groups**: Network security controls
- **Monitoring**: CloudWatch integration and optional observability stack

## Prerequisites

1. **AWS CLI**: Configured with appropriate credentials
2. **Terraform**: Version >= 1.5
3. **kubectl**: For Kubernetes cluster management
4. **Helm**: For deploying Kubernetes applications

```bash
# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update && sudo apt-get install helm
```

## State Management

This configuration uses S3 for remote state storage with DynamoDB for state locking.

### Setup State Backend

1. Create S3 bucket for state storage:
```bash
aws s3 mb s3://electra-terraform-state-$(date +%s) --region us-west-2
```

2. Create DynamoDB table for state locking:
```bash
aws dynamodb create-table \
  --table-name electra-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-west-2
```

3. Update the backend configuration in `main.tf` or create a backend config file:
```hcl
# backend.conf
bucket         = "your-terraform-state-bucket"
key            = "infrastructure/terraform.tfstate"
region         = "us-west-2"
encrypt        = true
dynamodb_table = "electra-terraform-locks"
```

## Deployment

### 1. Initialize Terraform

```bash
# Initialize with remote backend
terraform init -backend-config=backend.conf

# Or initialize with local state (not recommended for production)
terraform init
```

### 2. Create Environment-Specific Variables

Create `terraform.tfvars` files for each environment:

**staging.tfvars:**
```hcl
environment = "staging"
aws_region  = "us-west-2"
vpc_cidr    = "10.0.0.0/16"

# RDS Configuration
rds_instance_class = "db.t3.micro"
rds_allocated_storage = 20

# EKS Configuration
eks_node_groups = {
  general = {
    instance_types = ["t3.small"]
    capacity_type  = "SPOT"
    scaling_config = {
      desired_size = 2
      max_size     = 5
      min_size     = 1
    }
    update_config = {
      max_unavailable_percentage = 25
    }
  }
}

# Application Configuration
app_replica_count = 2
django_secret_key = "your_staging_KEY_goes_here"
jwt_secret_key   = "your_staging_JWT_KEY_goes_here"

# Domain Configuration
domain_name = "staging.electra.example.com"
```

**production.tfvars:**
```hcl
environment = "production"
aws_region  = "us-west-2"
vpc_cidr    = "10.1.0.0/16"

# RDS Configuration
rds_instance_class = "db.r5.large"
rds_allocated_storage = 100
rds_max_allocated_storage = 1000
rds_backup_retention_period = 30

# EKS Configuration
eks_node_groups = {
  general = {
    instance_types = ["t3.medium", "t3a.medium"]
    capacity_type  = "ON_DEMAND"
    scaling_config = {
      desired_size = 3
      max_size     = 10
      min_size     = 2
    }
    update_config = {
      max_unavailable_percentage = 25
    }
  }
  compute = {
    instance_types = ["c5.large", "c5a.large"]
    capacity_type  = "ON_DEMAND"
    scaling_config = {
      desired_size = 2
      max_size     = 5
      min_size     = 0
    }
    update_config = {
      max_unavailable_percentage = 25
    }
  }
}

# Application Configuration
app_replica_count = 5
app_cpu_limit    = "1000m"
app_memory_limit = "1Gi"

# Security Configuration
allowed_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"]
enable_waf = true

# Domain Configuration
domain_name = "electra.example.com"
```

### 3. Plan and Apply

```bash
# Plan for staging
terraform plan -var-file=staging.tfvars -out=staging.tfplan

# Apply staging
terraform apply staging.tfplan

# Plan for production (use workspace or separate state)
terraform workspace new production  # If using workspaces
terraform plan -var-file=production.tfvars -out=production.tfplan

# Apply production
terraform apply production.tfplan
```

### 4. Configure kubectl

After deployment, configure kubectl to access the cluster:

```bash
# Get the kubectl config command from terraform output
terraform output kubectl_config_command

# Execute the command (example)
aws eks update-kubeconfig --region us-west-2 --name electra-staging

# Verify connection
kubectl get nodes
kubectl get namespaces
```

## Module Structure

```
modules/
├── vpc/           # VPC, subnets, routing, NAT gateways
├── eks/           # EKS cluster, node groups, IRSA
├── rds/           # PostgreSQL database, security groups
├── s3/            # S3 buckets for media and backups
├── iam/           # IAM roles, policies, service accounts
└── secrets/       # AWS Secrets Manager secrets
```

### VPC Module

Creates a production-ready VPC with:
- Public subnets for load balancers
- Private subnets for application workloads
- Database subnets for RDS
- NAT gateways for outbound internet access
- VPC endpoints for AWS services

### EKS Module

Provisions:
- EKS cluster with latest supported version
- Managed node groups with auto-scaling
- IRSA (IAM Roles for Service Accounts)
- Security groups with minimal required access
- Add-ons: VPC CNI, CoreDNS, kube-proxy

### RDS Module

Sets up:
- PostgreSQL instance with encryption
- Automated backups and point-in-time recovery
- Multi-AZ deployment for production
- Enhanced monitoring
- Security groups with restricted access

### S3 Module

Creates:
- Media files bucket with versioning
- Backup storage bucket with lifecycle policies
- Server-side encryption
- Access logging
- CORS configuration for web access

### IAM Module

Configures:
- EKS service roles
- Node group instance roles
- IRSA for application pods
- S3 access policies
- Secrets Manager access policies

### Secrets Module

Manages:
- Database connection strings
- Application secrets (Django, JWT keys)
- Rotation configuration
- Cross-service access policies

## Post-Deployment Configuration

### 1. Install Essential Kubernetes Applications

```bash
# Install AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=electra-staging \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Install EFS CSI Driver (for persistent volumes)
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
helm install aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
  --namespace kube-system

# Install Cluster Autoscaler
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=electra-staging \
  --set awsRegion=us-west-2
```

### 2. Configure DNS and SSL

```bash
# Install external-dns for automatic DNS management
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm install external-dns external-dns/external-dns \
  --set provider=aws \
  --set aws.zoneType=public \
  --set txtOwnerId=electra-staging

# Install cert-manager for automatic SSL certificates
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```

### 3. Deploy Monitoring Stack (Optional)

```bash
# Install Prometheus and Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=your_secure_password_here
```

## Maintenance Commands

### Update Infrastructure

```bash
# Check for updates
terraform plan -var-file=staging.tfvars

# Apply updates
terraform apply -var-file=staging.tfvars
```

### Upgrade EKS Cluster

```bash
# Update cluster version in variables
# Then apply changes
terraform apply -var-file=staging.tfvars -target=module.eks
```

### Scale Node Groups

```bash
# Update node group configuration in tfvars
# Apply changes
terraform apply -var-file=staging.tfvars -target=module.eks.aws_eks_node_group
```

## Disaster Recovery

### Backup State

```bash
# Download current state
terraform state pull > terraform.tfstate.backup.$(date +%Y%m%d)
```

### Restore from Backup

```bash
# Push backup state (use with caution)
terraform state push terraform.tfstate.backup.20231015
```

## Destroy Infrastructure

**⚠️ WARNING: This will destroy ALL resources**

```bash
# Destroy staging environment
terraform destroy -var-file=staging.tfvars

# Destroy production environment (requires extra confirmation)
terraform destroy -var-file=production.tfvars
```

## Troubleshooting

### Common Issues

1. **State Lock**: If terraform is stuck on a lock:
```bash
terraform force-unlock LOCK_ID
```

2. **EKS Access Issues**: Ensure your AWS credentials have proper permissions:
```bash
aws sts get-caller-identity
aws eks describe-cluster --name electra-staging
```

3. **kubectl Connection**: Update kubeconfig:
```bash
aws eks update-kubeconfig --region us-west-2 --name electra-staging
```

### Debugging

```bash
# Enable detailed logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Run terraform commands
terraform plan -var-file=staging.tfvars
```

## Security Considerations

- All secrets are stored in AWS Secrets Manager
- Network access is restricted using security groups
- EKS uses IRSA for pod-level permissions
- S3 buckets have versioning and encryption enabled
- RDS has encryption at rest enabled
- VPC uses private subnets for application workloads

## Cost Optimization

- Use Spot instances for non-production workloads
- Enable S3 lifecycle policies for old backups
- Configure cluster autoscaler for dynamic scaling
- Use Reserved Instances for predictable workloads
- Monitor costs with AWS Cost Explorer

## Support

For infrastructure issues:
1. Check Terraform logs
2. Review AWS CloudTrail events
3. Verify IAM permissions
4. Check resource limits and quotas

For application deployment issues:
1. Check Kubernetes events: `kubectl get events`
2. Review pod logs: `kubectl logs -f deployment/electra-web`
3. Verify secrets and configmaps
4. Check service endpoints and ingress configuration