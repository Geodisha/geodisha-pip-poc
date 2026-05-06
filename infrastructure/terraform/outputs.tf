output "vpc_network_name" {
  description = "VPC Network Name"
  value       = google_compute_network.vpc_network.name
}

output "vpc_connector_id" {
  description = "VPC Access Connector ID"
  value       = google_vpc_access_connector.connector.id
}

output "cloud_sql_connection_name" {
  description = "Cloud SQL Connection Name"
  value       = google_sql_database_instance.main.connection_name
}

output "cloud_sql_private_ip" {
  description = "Cloud SQL Private IP"
  value       = google_sql_database_instance.main.private_ip_address
}

output "media_bucket_name" {
  description = "Media Storage Bucket Name"
  value       = google_storage_bucket.media_bucket.name
}

output "ml_models_bucket_name" {
  description = "ML Models Storage Bucket Name"
  value       = google_storage_bucket.ml_models_bucket.name
}

output "bigquery_dataset_id" {
  description = "BigQuery Dataset ID"
  value       = google_bigquery_dataset.analytics.dataset_id
}

output "artifact_registry_repository" {
  description = "Artifact Registry Repository"
  value       = google_artifact_registry_repository.docker_repo.name
}

output "service_account_email" {
  description = "Cloud Run Service Account Email"
  value       = google_service_account.cloud_run_sa.email
}
