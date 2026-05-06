#!/bin/bash
# GeoDisha - GCP Authentication Setup Script
# This script sets up proper GCP authentication for the backend

set -e

echo "🔐 GeoDisha GCP Authentication Setup"
echo "====================================="
echo ""

PROJECT_ID="geo-pulse-463507"
SERVICE_ACCOUNT_NAME="geodisha-backend"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="./geodisha-backend-key.json"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI not found. Please install it first:"
    echo "   https://cloud.google.com/sdk/docs/install"
    exit 1
fi

echo "✅ gcloud CLI found"
echo ""

# Check if already authenticated
if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "✅ Already authenticated with gcloud"
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
    echo "   Current project: ${CURRENT_PROJECT}"
    echo ""
else
    echo "⚠️  Not authenticated with gcloud"
    echo "   Please run: gcloud auth login"
    exit 1
fi

# Set project
echo "📦 Setting project to: ${PROJECT_ID}"
gcloud config set project ${PROJECT_ID}
echo ""

# Check if service account exists
if gcloud iam service-accounts describe ${SERVICE_ACCOUNT_EMAIL} &> /dev/null; then
    echo "✅ Service account already exists: ${SERVICE_ACCOUNT_EMAIL}"
else
    echo "📝 Creating service account: ${SERVICE_ACCOUNT_NAME}"
    gcloud iam service-accounts create ${SERVICE_ACCOUNT_NAME} \
        --display-name="GeoDisha Backend API" \
        --description="Service account for GeoDisha backend to access BigQuery"
    echo "✅ Service account created"
fi
echo ""

# Grant BigQuery permissions
echo "🔑 Granting BigQuery permissions..."

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/bigquery.dataViewer" \
    --condition=None \
    > /dev/null 2>&1

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/bigquery.jobUser" \
    --condition=None \
    > /dev/null 2>&1

echo "✅ Permissions granted:"
echo "   - roles/bigquery.dataViewer"
echo "   - roles/bigquery.jobUser"
echo ""

# Create key file
if [ -f "${KEY_FILE}" ]; then
    echo "⚠️  Key file already exists: ${KEY_FILE}"
    read -p "   Overwrite? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "   Keeping existing key file"
    else
        echo "🔑 Creating new key file..."
        gcloud iam service-accounts keys create ${KEY_FILE} \
            --iam-account=${SERVICE_ACCOUNT_EMAIL}
        echo "✅ New key file created: ${KEY_FILE}"
    fi
else
    echo "🔑 Creating key file: ${KEY_FILE}"
    gcloud iam service-accounts keys create ${KEY_FILE} \
        --iam-account=${SERVICE_ACCOUNT_EMAIL}
    echo "✅ Key file created: ${KEY_FILE}"
fi
echo ""

# Update .env file
ENV_FILE=".env"
if [ ! -f "${ENV_FILE}" ]; then
    echo "📝 Creating .env file from .env.example..."
    cp .env.example ${ENV_FILE}
fi

# Add/update GOOGLE_APPLICATION_CREDENTIALS
ABS_KEY_PATH="$(cd "$(dirname "${KEY_FILE}")" && pwd)/$(basename "${KEY_FILE}")"

if grep -q "GOOGLE_APPLICATION_CREDENTIALS=" ${ENV_FILE}; then
    # Update existing line (macOS compatible)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|^GOOGLE_APPLICATION_CREDENTIALS=.*|GOOGLE_APPLICATION_CREDENTIALS=${ABS_KEY_PATH}|" ${ENV_FILE}
    else
        sed -i "s|^GOOGLE_APPLICATION_CREDENTIALS=.*|GOOGLE_APPLICATION_CREDENTIALS=${ABS_KEY_PATH}|" ${ENV_FILE}
    fi
    echo "✅ Updated GOOGLE_APPLICATION_CREDENTIALS in .env"
else
    # Add new line
    echo "" >> ${ENV_FILE}
    echo "# GCP Authentication" >> ${ENV_FILE}
    echo "GOOGLE_APPLICATION_CREDENTIALS=${ABS_KEY_PATH}" >> ${ENV_FILE}
    echo "✅ Added GOOGLE_APPLICATION_CREDENTIALS to .env"
fi

# Update GCP_PROJECT_ID
if grep -q "^GCP_PROJECT_ID=" ${ENV_FILE}; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|^GCP_PROJECT_ID=.*|GCP_PROJECT_ID=${PROJECT_ID}|" ${ENV_FILE}
    else
        sed -i "s|^GCP_PROJECT_ID=.*|GCP_PROJECT_ID=${PROJECT_ID}|" ${ENV_FILE}
    fi
else
    echo "GCP_PROJECT_ID=${PROJECT_ID}" >> ${ENV_FILE}
fi

echo ""

# Test authentication
echo "🧪 Testing BigQuery authentication..."
python3 << EOF
import sys
try:
    from google.cloud import bigquery
    from google.oauth2 import service_account
    
    credentials = service_account.Credentials.from_service_account_file(
        '${KEY_FILE}',
        scopes=["https://www.googleapis.com/auth/bigquery"]
    )
    client = bigquery.Client(project='${PROJECT_ID}', credentials=credentials)
    
    # Test query
    query = "SELECT COUNT(*) as count FROM \`${PROJECT_ID}.geo_pulse_data.INFORMATION_SCHEMA.TABLES\`"
    result = list(client.query(query).result())
    
    print("✅ Authentication successful!")
    print(f"   Tables in dataset: {result[0].count}")
    sys.exit(0)
except Exception as e:
    print(f"❌ Authentication failed: {e}")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Setup Complete!"
    echo ""
    echo "Next steps:"
    echo "1. Start the backend:"
    echo "   cd /Users/conglomerateit/Documents/GEODISHA/Code/gd_playground/geodisha-mobile-app/backend/api-gateway"
    echo "   export GOOGLE_APPLICATION_CREDENTIALS=\"${ABS_KEY_PATH}\""
    echo "   python3 -m uvicorn main:app --reload --port 8000"
    echo ""
    echo "2. Test the API:"
    echo "   curl http://localhost:8000/health"
    echo "   curl http://localhost:8000/api/v1/command-center/overview"
    echo ""
    echo "⚠️  Security Notes:"
    echo "   - Never commit ${KEY_FILE} to git"
    echo "   - Rotate keys every 90 days"
    echo "   - Use Workload Identity in production"
else
    echo ""
    echo "❌ Setup failed. Please check the errors above."
    echo ""
    echo "Common issues:"
    echo "1. Not authenticated with gcloud: gcloud auth login"
    echo "2. Wrong project: gcloud config set project ${PROJECT_ID}"
    echo "3. Insufficient permissions: Contact GCP admin"
    exit 1
fi
