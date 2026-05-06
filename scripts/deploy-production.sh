#!/bin/bash

# GeoDisha Mobile Platform - Production Deployment Script

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 GeoDisha Production Deployment${NC}"
echo "=================================="

# Check if PROJECT_ID is set
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Error: PROJECT_ID environment variable not set${NC}"
    echo "Usage: PROJECT_ID=your-project-id ./scripts/deploy-production.sh"
    exit 1
fi

echo "Project ID: $PROJECT_ID"
read -p "Proceed with deployment? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled"
    exit 0
fi

# Set variables
REGION="us-central1"
ENVIRONMENT="production"

echo -e "\n${YELLOW}Step 1: Building backend services...${NC}"

# Build Auth Service
echo "Building auth-service..."
cd backend/services/auth
gcloud builds submit --tag gcr.io/${PROJECT_ID}/auth-service:latest --project ${PROJECT_ID}

# Build Intelligence Service
echo "Building intelligence-service..."
cd ../intelligence
gcloud builds submit --tag gcr.io/${PROJECT_ID}/intelligence-service:latest --project ${PROJECT_ID}

echo -e "${GREEN}✓ Backend services built${NC}"

echo -e "\n${YELLOW}Step 2: Deploying to Cloud Run...${NC}"

# Deploy Auth Service
gcloud run deploy auth-service \
    --image gcr.io/${PROJECT_ID}/auth-service:latest \
    --platform managed \
    --region ${REGION} \
    --project ${PROJECT_ID} \
    --allow-unauthenticated \
    --set-env-vars "ENVIRONMENT=${ENVIRONMENT},PROJECT_ID=${PROJECT_ID}" \
    --min-instances 1 \
    --max-instances 10 \
    --memory 512Mi

# Deploy Intelligence Service
gcloud run deploy intelligence-service \
    --image gcr.io/${PROJECT_ID}/intelligence-service:latest \
    --platform managed \
    --region ${REGION} \
    --project ${PROJECT_ID} \
    --allow-unauthenticated \
    --set-env-vars "ENVIRONMENT=${ENVIRONMENT},PROJECT_ID=${PROJECT_ID}" \
    --min-instances 1 \
    --max-instances 20 \
    --memory 1Gi

echo -e "${GREEN}✓ Services deployed to Cloud Run${NC}"

echo -e "\n${YELLOW}Step 3: Applying infrastructure changes...${NC}"

cd ../../../../infrastructure/environments/production
terraform init
terraform apply -var="project_id=${PROJECT_ID}" -var="environment=${ENVIRONMENT}" -auto-approve

echo -e "${GREEN}✓ Infrastructure updated${NC}"

echo -e "\n${YELLOW}Step 4: Verifying deployment...${NC}"

# Get service URLs
AUTH_URL=$(gcloud run services describe auth-service --region ${REGION} --project ${PROJECT_ID} --format 'value(status.url)')
INTEL_URL=$(gcloud run services describe intelligence-service --region ${REGION} --project ${PROJECT_ID} --format 'value(status.url)')

# Health checks
echo "Checking auth-service health..."
if curl -f ${AUTH_URL}/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓ auth-service is healthy${NC}"
else
    echo -e "${RED}✗ auth-service health check failed${NC}"
fi

echo "Checking intelligence-service health..."
if curl -f ${INTEL_URL}/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓ intelligence-service is healthy${NC}"
else
    echo -e "${RED}✗ intelligence-service health check failed${NC}"
fi

echo -e "\n${GREEN}=================================="
echo "✅ Deployment Complete!"
echo "=================================="
echo -e "${NC}"
echo "Service URLs:"
echo "  Auth Service: ${AUTH_URL}"
echo "  Intelligence Service: ${INTEL_URL}"
echo ""
echo "Next steps:"
echo "1. Update mobile app API endpoints"
echo "2. Test all critical flows"
echo "3. Monitor logs: gcloud logging read --limit 50"
echo "4. Set up alerts and monitoring"
