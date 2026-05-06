terraform {
  required_version = ">= 1.0"
  
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
    prefix = "terraform/state"
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

# Enable Required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "firestore.googleapis.com",
    "sqladmin.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudfunctions.googleapis.com",
    "pubsub.googleapis.com",
    "aiplatform.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudmonitoring.googleapis.com",
    "logging.googleapis.com",
    "firebase.googleapis.com",
    "identitytoolkit.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "vpcaccess.googleapis.com",
  ])

  service            = each.key
  disable_on_destroy = false
}

# VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = "geodisha-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.required_apis]
}

resource "google_compute_subnetwork" "private_subnet" {
  name          = "geodisha-private-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id

  private_ip_google_access = true
}

# VPC Access Connector for Cloud Run
resource "google_vpc_access_connector" "connector" {
  name          = "geodisha-vpc-connector"
  region        = var.region
  network       = google_compute_network.vpc_network.name
  ip_cidr_range = "10.8.0.0/28"
  
  depends_on = [google_project_service.required_apis]
}

# Firestore Database
resource "google_firestore_database" "database" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.firestore_region
  type        = "FIRESTORE_NATIVE"

  depends_on = [google_project_service.required_apis]
}

# Cloud Storage Buckets
resource "google_storage_bucket" "media_bucket" {
  name          = "${var.project_id}-media"
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  versioning {
    enabled = true
  }
}

resource "google_storage_bucket" "ml_models_bucket" {
  name          = "${var.project_id}-ml-models"
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true
}

# Cloud SQL Instance (PostgreSQL)
resource "google_sql_database_instance" "main" {
  name             = "geodisha-db-instance"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier              = var.db_tier
    availability_type = "REGIONAL"
    disk_size         = 100
    disk_type         = "PD_SSD"
    disk_autoresize   = true

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      start_time                     = "03:00"
      backup_retention_settings {
        retained_backups = 7
      }
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc_network.id
    }

    database_flags {
      name  = "max_connections"
      value = "200"
    }
  }

  deletion_protection = true

  depends_on = [google_project_service.required_apis]
}

resource "google_sql_database" "geodisha_db" {
  name     = "geodisha"
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "db_user" {
  name     = "geodisha_app"
  instance = google_sql_database_instance.main.name
  password = var.db_password
}

# BigQuery Dataset
resource "google_bigquery_dataset" "analytics" {
  dataset_id                 = "geodisha_analytics"
  location                   = var.region
  default_table_expiration_ms = null

  labels = {
    env = var.environment
  }

  depends_on = [google_project_service.required_apis]
}

# Pub/Sub Topics
resource "google_pubsub_topic" "grievance_events" {
  name = "grievance-events"

  message_retention_duration = "604800s" # 7 days

  depends_on = [google_project_service.required_apis]
}

resource "google_pubsub_topic" "visit_events" {
  name = "visit-events"

  depends_on = [google_project_service.required_apis]
}

resource "google_pubsub_topic" "analytics_events" {
  name = "analytics-events"

  depends_on = [google_project_service.required_apis]
}

# Artifact Registry for Docker Images
resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = "geodisha-docker"
  description   = "Docker repository for GeoDisha services"
  format        = "DOCKER"

  depends_on = [google_project_service.required_apis]
}

# Secret Manager Secrets
resource "google_secret_manager_secret" "db_connection_string" {
  secret_id = "db-connection-string"

  replication {
    auto {}
  }

  depends_on = [google_project_service.required_apis]
}

resource "google_secret_manager_secret" "jwt_secret" {
  secret_id = "jwt-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.required_apis]
}

resource "google_secret_manager_secret" "api_keys" {
  secret_id = "api-keys"

  replication {
    auto {}
  }

  depends_on = [google_project_service.required_apis]
}

# Service Account for Cloud Run
resource "google_service_account" "cloud_run_sa" {
  account_id   = "geodisha-cloud-run"
  display_name = "GeoDisha Cloud Run Service Account"
}

# IAM Roles for Service Account
resource "google_project_iam_member" "cloud_run_firestore" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_cloudsql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_storage" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_secrets" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_vertex_ai" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}
