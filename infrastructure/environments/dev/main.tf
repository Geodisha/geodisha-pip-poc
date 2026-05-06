terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
  
  backend "gcs" {
    bucket = "geodisha-terraform-state"
    prefix = "dev/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# Networking Module
module "networking" {
  source = "../../modules/networking"
  
  project_id  = var.project_id
  region      = var.region
  environment = var.environment
}

# Cloud Run Services
module "auth_service" {
  source = "../../modules/cloud-run"
  
  project_id   = var.project_id
  region       = var.region
  service_name = "auth-service"
  image        = "gcr.io/${var.project_id}/auth-service:latest"
  
  env_vars = {
    ENVIRONMENT = var.environment
    PROJECT_ID  = var.project_id
  }
  
  min_instances = 0
  max_instances = 10
}

module "intelligence_service" {
  source = "../../modules/cloud-run"
  
  project_id   = var.project_id
  region       = var.region
  service_name = "intelligence-service"
  image        = "gcr.io/${var.project_id}/intelligence-service:latest"
  
  env_vars = {
    ENVIRONMENT = var.environment
    PROJECT_ID  = var.project_id
  }
  
  min_instances = 0
  max_instances = 20
}

# Cloud SQL
module "cloud_sql" {
  source = "../../modules/databases"
  
  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  
  database_version = "POSTGRES_15"
  tier            = "db-f1-micro"  # Small for dev
  disk_size       = 10
}

# Cloud Storage
module "storage" {
  source = "../../modules/storage"
  
  project_id  = var.project_id
  environment = var.environment
  
  buckets = {
    media   = "geodisha-${var.environment}-media"
    backups = "geodisha-${var.environment}-backups"
    exports = "geodisha-${var.environment}-exports"
  }
}

# BigQuery
resource "google_bigquery_dataset" "analytics" {
  dataset_id                 = "geodisha_analytics_${var.environment}"
  location                   = var.region
  default_table_expiration_ms = 31536000000  # 1 year
  
  labels = {
    environment = var.environment
  }
}

# Outputs
output "auth_service_url" {
  value = module.auth_service.service_url
}

output "intelligence_service_url" {
  value = module.intelligence_service.service_url
}

output "database_connection_name" {
  value = module.cloud_sql.connection_name
}
