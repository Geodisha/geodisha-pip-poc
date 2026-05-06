#!/bin/bash

# GeoDisha Backend - Quick Start Script
# This script runs the API with just BigQuery dependencies

set -e

echo "🚀 GeoDisha API - Quick Start"
echo "=============================="

cd "$(dirname "$0")/.."

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
    echo "✅ Virtual environment activated"
else
    echo "⚠️  No virtual environment found. Creating one..."
    python3.11 -m venv venv
    source venv/bin/activate
    
    echo "📦 Installing minimal dependencies..."
    pip install --upgrade pip
    pip install \
        fastapi==0.115.0 \
        uvicorn[standard]==0.32.0 \
        pydantic==2.10.0 \
        pydantic-settings==2.5.0 \
        google-cloud-bigquery==3.25.0 \
        google-cloud-logging==3.11.0 \
        python-jose[cryptography]==3.3.0 \
        passlib[bcrypt]==1.7.4 \
        python-multipart==0.0.9 \
        python-dotenv==1.0.0
    
    echo "✅ Dependencies installed"
fi

echo ""
echo "🌐 Starting GeoDisha API Gateway..."
echo "📊 Connected to BigQuery: Snail_track_mvp1.visit_records_bhongir"
echo ""

# Set environment variables
export ENVIRONMENT=development
export GCP_PROJECT_ID=${GCP_PROJECT_ID:-"your-project-id"}
export LOG_LEVEL=INFO

# Start the server
python3 -m uvicorn main:app --reload --host 0.0.0.0 --port 8080 --log-level info
