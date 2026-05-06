variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-south1" # Mumbai region for India
}

variable "firestore_region" {
  description = "Firestore Region"
  type        = string
  default     = "asia-south1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "db_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-custom-4-16384" # 4 vCPUs, 16GB RAM
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
