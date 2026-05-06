#!/bin/bash

# Enable required Google Cloud APIs for GeoDisha Platform

set -e

echo "🔧 Enabling Google Cloud APIs..."

# Check if gcloud is configured
if ! gcloud config get-value project &>/dev/null; then
    echo "Error: Please run 'gcloud init' first to set up your project"
    exit 1
fi

PROJECT_ID=$(gcloud config get-value project)
echo "Project: $PROJECT_ID"

# Array of APIs to enable
APIS=(
    "compute.googleapis.com"                  # Compute Engine API
    "run.googleapis.com"                      # Cloud Run API
    "sqladmin.googleapis.com"                 # Cloud SQL Admin API
    "storage-api.googleapis.com"              # Cloud Storage API
    "storage-component.googleapis.com"        # Cloud Storage
    "firestore.googleapis.com"                # Cloud Firestore API
    "aiplatform.googleapis.com"               # Vertex AI API
    "cloudscheduler.googleapis.com"           # Cloud Scheduler API
    "pubsub.googleapis.com"                   # Cloud Pub/Sub API
    "cloudresourcemanager.googleapis.com"     # Cloud Resource Manager API
    "iam.googleapis.com"                      # Identity and Access Management API
    "iamcredentials.googleapis.com"           # IAM Service Account Credentials API
    "cloudapis.googleapis.com"                # Google Cloud APIs
    "cloudbuild.googleapis.com"               # Cloud Build API
    "containerregistry.googleapis.com"        # Container Registry API
    "artifactregistry.googleapis.com"         # Artifact Registry API
    "secretmanager.googleapis.com"            # Secret Manager API
    "cloudtrace.googleapis.com"               # Cloud Trace API
    "logging.googleapis.com"                  # Cloud Logging API
    "monitoring.googleapis.com"               # Cloud Monitoring API
    "cloudprofiler.googleapis.com"            # Cloud Profiler API
    "bigquery.googleapis.com"                 # BigQuery API
    "bigquerystorage.googleapis.com"          # BigQuery Storage API
    "dataflow.googleapis.com"                 # Dataflow API
    "servicenetworking.googleapis.com"        # Service Networking API
    "vpcaccess.googleapis.com"                # Serverless VPC Access API
    "redis.googleapis.com"                    # Cloud Memorystore for Redis
    "translate.googleapis.com"                # Cloud Translation API
    "language.googleapis.com"                 # Natural Language API
    "firebase.googleapis.com"                 # Firebase Management API
)

# Enable APIs
for api in "${APIS[@]}"; do
    echo "Enabling $api..."
    gcloud services enable "$api" --project="$PROJECT_ID"
done

echo "✅ All APIs enabled successfully!"

# Create service account for backend services
echo ""
echo "Creating service accounts..."

SA_NAME="geodisha-backend-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" &>/dev/null; then
    echo "Service account $SA_EMAIL already exists"
else
    gcloud iam service-accounts create "$SA_NAME" \
        --display-name="GeoDisha Backend Service Account" \
        --project="$PROJECT_ID"
    echo "✅ Service account created"
fi

# Grant necessary roles
echo "Granting IAM roles..."
ROLES=(
    "roles/cloudsql.client"
    "roles/datastore.user"
    "roles/storage.objectAdmin"
    "roles/pubsub.publisher"
    "roles/aiplatform.user"
    "roles/logging.logWriter"
    "roles/monitoring.metricWriter"
)

for role in "${ROLES[@]}"; do
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SA_EMAIL" \
        --role="$role" \
        --quiet
done

echo "✅ IAM roles granted"

echo ""
echo "🎉 Setup complete!"
echo "Service Account: $SA_EMAIL"
echo ""
echo "Next steps:"
echo "1. Create a service account key:"
echo "   gcloud iam service-accounts keys create key.json --iam-account=$SA_EMAIL"
echo "2. Set environment variable:"
echo "   export GOOGLE_APPLICATION_CREDENTIALS=key.json"
