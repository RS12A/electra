# Electra Infrastructure Outputs

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of database subnets"
  value       = module.vpc.database_subnet_ids
}

# EKS Outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = module.eks.cluster_version
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "worker_security_group_id" {
  description = "Security group ID attached to the EKS worker nodes"
  value       = module.eks.worker_security_group_id
}

output "oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks.cluster_oidc_issuer_url
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.endpoint
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.port
}

output "rds_instance_id" {
  description = "RDS instance ID"
  value       = module.rds.instance_id
}

output "rds_instance_arn" {
  description = "RDS instance ARN"
  value       = module.rds.instance_arn
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = module.rds.security_group_id
}

# S3 Outputs
output "media_bucket_id" {
  description = "Media storage bucket ID"
  value       = module.s3.media_bucket_id
}

output "media_bucket_arn" {
  description = "Media storage bucket ARN"
  value       = module.s3.media_bucket_arn
}

output "backup_bucket_id" {
  description = "Backup storage bucket ID"
  value       = module.s3.backup_bucket_id
}

output "backup_bucket_arn" {
  description = "Backup storage bucket ARN"
  value       = module.s3.backup_bucket_arn
}

# IAM Outputs
output "app_service_account_arn" {
  description = "ARN of the application service account"
  value       = module.iam.app_service_account_arn
}

output "backup_service_account_arn" {
  description = "ARN of the backup service account"
  value       = module.iam.backup_service_account_arn
}

# Secrets Manager Outputs
output "database_secret_arn" {
  description = "ARN of the database secret in Secrets Manager"
  value       = module.secrets.database_secret_arn
  sensitive   = true
}

output "app_secrets_arn" {
  description = "ARN of the application secrets in Secrets Manager"
  value       = module.secrets.app_secrets_arn
  sensitive   = true
}

# Kubernetes Namespace
output "kubernetes_namespace" {
  description = "Kubernetes namespace for the application"
  value       = kubernetes_namespace.electra.metadata[0].name
}

# Connection Information
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

# Application URLs (if load balancer is configured)
output "application_url" {
  description = "Application URL"
  value       = var.domain_name != "" ? "https://${var.subdomain != "" ? "${var.subdomain}." : ""}${var.domain_name}" : "To be configured after load balancer setup"
}

# Monitoring and Logging URLs
output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = var.enable_monitoring ? "https://grafana.${var.domain_name}" : "Monitoring not enabled"
}

output "kibana_url" {
  description = "Kibana dashboard URL"
  value       = var.enable_logging ? "https://kibana.${var.domain_name}" : "Logging not enabled"
}

# Resource Information for Operations
output "resource_summary" {
  description = "Summary of created resources"
  value = {
    environment     = var.environment
    aws_region     = var.aws_region
    cluster_name   = module.eks.cluster_name
    vpc_id         = module.vpc.vpc_id
    rds_endpoint   = module.rds.endpoint
    media_bucket   = module.s3.media_bucket_id
    backup_bucket  = module.s3.backup_bucket_id
    namespace      = kubernetes_namespace.electra.metadata[0].name
  }
}

# Cost Estimation Tags
output "cost_tags" {
  description = "Tags for cost tracking"
  value = {
    Project     = "electra"
    Environment = var.environment
    ManagedBy   = "terraform"
    CostCenter  = "platform"
  }
}

# Security Information
output "security_groups" {
  description = "Security group information"
  value = {
    eks_cluster_sg = module.eks.cluster_security_group_id
    eks_worker_sg  = module.eks.worker_security_group_id
    rds_sg         = module.rds.security_group_id
  }
}

# Backup Information
output "backup_configuration" {
  description = "Backup configuration details"
  value = {
    rds_backup_retention = var.rds_backup_retention_period
    rds_backup_window   = var.rds_backup_window
    backup_bucket       = module.s3.backup_bucket_id
    automated_backups   = var.enable_backups
  }
}