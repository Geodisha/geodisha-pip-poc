#!/bin/bash

# GeoDisha API Gateway Deployment Script
set -e

echo "🚀 Deploying GeoDisha API Gateway to Cloud Run..."

# Configuration
PROJECT_ID=${GCP_PROJECT_ID:-"your-project-id"}
REGION=${GCP_REGION:-"asia-south1"}
SERVICE_NAME="geodisha-api-gateway"
IMAGE_NAME="geodisha-api-gateway"

# Build and push Docker image
echo "📦 Building Docker image..."
gcloud builds submit --tag gcr.io/${PROJECT_ID}/${IMAGE_NAME}:latest

# Deploy to Cloud Run
echo "🌐 Deploying to Cloud Run..."
gcloud run deploy ${SERVICE_NAME} \
  --image gcr.io/${PROJECT_ID}/${IMAGE_NAME}:latest \
  --platform managed \
  --region ${REGION} \
  --allow-unauthenticated \
  --min-instances 1 \
  --max-instances 10 \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300 \
  --concurrency 80 \
  --port 8080 \
  --set-env-vars "ENVIRONMENT=production,GCP_PROJECT_ID=${PROJECT_ID},GCP_REGION=${REGION}" \
  --set-secrets "JWT_SECRET_KEY=jwt-secret:latest,DB_PASSWORD=db-connection-string:latest" \
  --vpc-connector geodisha-vpc-connector \
  --service-account geodisha-cloud-run@${PROJECT_ID}.iam.gserviceaccount.com

echo "✅ Deployment complete!"
echo "Service URL:"
gcloud run services describe ${SERVICE_NAME} --region ${REGION} --format 'value(status.url)'
