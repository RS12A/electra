# Electra Infrastructure Variables

# General Configuration
variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be either 'staging' or 'production'."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# EKS Configuration
variable "eks_node_groups" {
  description = "EKS node group configurations"
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    scaling_config = object({
      desired_size = number
      max_size     = number
      min_size     = number
    })
    update_config = object({
      max_unavailable_percentage = number
    })
  }))
  
  default = {
    general = {
      instance_types = ["t3.medium", "t3a.medium"]
      capacity_type  = "ON_DEMAND"
      scaling_config = {
        desired_size = 2
        max_size     = 10
        min_size     = 1
      }
      update_config = {
        max_unavailable_percentage = 25
      }
    }
  }
}

# RDS Configuration
variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Initial allocated storage for RDS instance (GB)"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Maximum allocated storage for RDS instance (GB)"
  type        = number
  default     = 100
}

variable "rds_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "rds_backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "rds_maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "rds_monitoring_interval" {
  description = "Enhanced monitoring interval in seconds"
  type        = number
  default     = 60
}

# Application Secrets
variable "django_secret_key" {
  description = "Django secret key"
  type        = string
  sensitive   = true
  default     = "your_KEY_goes_here"
}

variable "jwt_secret_key" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
  default     = "your_KEY_goes_here"
}

# Feature Flags
variable "enable_monitoring" {
  description = "Enable monitoring stack (Prometheus, Grafana)"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable centralized logging (ELK stack)"
  type        = bool
  default     = true
}

variable "enable_backups" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "enable_ssl_redirect" {
  description = "Enable SSL redirect"
  type        = bool
  default     = true
}

# Domain Configuration
variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

variable "subdomain" {
  description = "Subdomain for the environment"
  type        = string
  default     = ""
}

# Container Configuration
variable "container_image" {
  description = "Container image for the application"
  type        = string
  default     = "ghcr.io/rs12a/electra:latest"
}

variable "container_tag" {
  description = "Container image tag"
  type        = string
  default     = "latest"
}

# Resource Limits
variable "app_cpu_request" {
  description = "CPU request for application container"
  type        = string
  default     = "250m"
}

variable "app_cpu_limit" {
  description = "CPU limit for application container"
  type        = string
  default     = "500m"
}

variable "app_memory_request" {
  description = "Memory request for application container"
  type        = string
  default     = "256Mi"
}

variable "app_memory_limit" {
  description = "Memory limit for application container"
  type        = string
  default     = "512Mi"
}

variable "app_replica_count" {
  description = "Number of application replicas"
  type        = number
  default     = 3
}

# Security Configuration
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the application"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_waf" {
  description = "Enable AWS WAF for additional security"
  type        = bool
  default     = true
}

variable "enable_encryption_at_rest" {
  description = "Enable encryption at rest for storage"
  type        = bool
  default     = true
}

variable "enable_encryption_in_transit" {
  description = "Enable encryption in transit"
  type        = bool
  default     = true
}