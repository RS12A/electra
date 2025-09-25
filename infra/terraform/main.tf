# Electra Infrastructure - Main Terraform Configuration
# Production-grade infrastructure provisioning for secure digital voting system

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes" 
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }

  # Configure remote state backend
  backend "s3" {
    # Configure these values in terraform init or via backend config file
    # bucket         = "electra-terraform-state"
    # key            = "infrastructure/terraform.tfstate"
    # region         = "us-west-2"
    # encrypt        = true
    # dynamodb_table = "electra-terraform-locks"
  }
}

# Configure providers
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

# Local values
locals {
  common_tags = {
    Project     = "electra"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "platform-team"
  }
  
  cluster_name = "electra-${var.environment}"
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  environment         = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = data.aws_availability_zones.available.names
  
  tags = local.common_tags
}

# EKS Cluster Module
module "eks" {
  source = "./modules/eks"
  
  cluster_name       = local.cluster_name
  environment        = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  
  node_groups = var.eks_node_groups
  
  tags = local.common_tags
}

# RDS Database Module
module "rds" {
  source = "./modules/rds"
  
  environment          = var.environment
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.database_subnet_ids
  allowed_cidr_blocks = [var.vpc_cidr]
  
  instance_class      = var.rds_instance_class
  allocated_storage   = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  
  backup_retention_period = var.rds_backup_retention_period
  backup_window          = var.rds_backup_window
  maintenance_window     = var.rds_maintenance_window
  
  monitoring_interval = var.rds_monitoring_interval
  
  tags = local.common_tags
}

# S3 Storage Module
module "s3" {
  source = "./modules/s3"
  
  environment = var.environment
  
  # Media storage bucket
  media_bucket_name = "electra-${var.environment}-media-${random_id.bucket_suffix.hex}"
  
  # Backup storage bucket
  backup_bucket_name = "electra-${var.environment}-backups-${random_id.bucket_suffix.hex}"
  
  tags = local.common_tags
}

# Random ID for unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# IAM Module for service accounts and roles
module "iam" {
  source = "./modules/iam"
  
  environment    = var.environment
  cluster_name   = local.cluster_name
  oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  
  # S3 bucket ARNs for IAM policies
  media_bucket_arn  = module.s3.media_bucket_arn
  backup_bucket_arn = module.s3.backup_bucket_arn
  
  # RDS instance ARN for IAM policies
  rds_instance_arn = module.rds.instance_arn
  
  tags = local.common_tags
}

# Secrets Manager Module
module "secrets" {
  source = "./modules/secrets"
  
  environment = var.environment
  
  # Database credentials
  database_url = module.rds.connection_string
  
  # Application secrets
  django_secret_key = var.django_secret_key
  jwt_secret_key   = var.jwt_secret_key
  
  tags = local.common_tags
}

# Security Group Rules
resource "aws_security_group_rule" "eks_to_rds" {
  type                     = "ingress"
  from_port               = 5432
  to_port                 = 5432
  protocol                = "tcp"
  source_security_group_id = module.eks.worker_security_group_id
  security_group_id       = module.rds.security_group_id
  description             = "Allow EKS workers to access RDS"
}

# Kubernetes manifests for core services
resource "kubernetes_namespace" "electra" {
  depends_on = [module.eks]
  
  metadata {
    name = "electra-${var.environment}"
    
    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

# Secret for database connection
resource "kubernetes_secret" "database" {
  depends_on = [kubernetes_namespace.electra]
  
  metadata {
    name      = "electra-database"
    namespace = kubernetes_namespace.electra.metadata[0].name
  }
  
  data = {
    database-url = module.rds.connection_string
  }
  
  type = "Opaque"
}

# Secret for application secrets
resource "kubernetes_secret" "app_secrets" {
  depends_on = [kubernetes_namespace.electra]
  
  metadata {
    name      = "electra-secrets"
    namespace = kubernetes_namespace.electra.metadata[0].name
  }
  
  data = {
    django-secret-key = var.django_secret_key
    jwt-secret-key   = var.jwt_secret_key
  }
  
  type = "Opaque"
}

# Persistent Volume Claims
resource "kubernetes_persistent_volume_claim" "static_files" {
  depends_on = [kubernetes_namespace.electra]
  
  metadata {
    name      = "electra-static-pvc"
    namespace = kubernetes_namespace.electra.metadata[0].name
  }
  
  spec {
    access_modes = ["ReadWriteMany"]
    
    resources {
      requests = {
        storage = "10Gi"
      }
    }
    
    storage_class_name = "efs-sc"
  }
}

resource "kubernetes_persistent_volume_claim" "media_files" {
  depends_on = [kubernetes_namespace.electra]
  
  metadata {
    name      = "electra-media-pvc"
    namespace = kubernetes_namespace.electra.metadata[0].name
  }
  
  spec {
    access_modes = ["ReadWriteMany"]
    
    resources {
      requests = {
        storage = "50Gi"
      }
    }
    
    storage_class_name = "efs-sc"
  }
}