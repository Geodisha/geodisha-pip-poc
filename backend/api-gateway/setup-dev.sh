#!/bin/bash

# Simple local development setup script
# This runs the FastAPI backend with minimal dependencies

set -e

echo "🚀 GeoDisha Backend - Local Development Setup"
echo "=============================================="

cd "$(dirname "$0")/.."

# Check Python version
if ! command -v python3.11 &> /dev/null; then
    echo "❌ Python 3.11 is required but not found."
    echo "Please install Python 3.11 first:"
    echo "  brew install python@3.11"
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment with Python 3.11..."
    python3.11 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
echo "⬆️  Upgrading pip..."
pip install --upgrade pip

# Install minimal dependencies for local dev
echo "📥 Installing dependencies..."
pip install \
    fastapi==0.115.0 \
    uvicorn[standard]==0.32.0 \
    pydantic==2.10.0 \
    pydantic-settings==2.5.0 \
    python-jose[cryptography]==3.3.0 \
    passlib[bcrypt]==1.7.4 \
    python-multipart==0.0.9 \
    python-dotenv==1.0.0 \
    requests==2.31.0

echo ""
echo "✅ Setup complete!"
echo ""
echo "To start the development server:"
echo "  cd backend/api-gateway"
echo "  source venv/bin/activate"
echo "  python3 -m uvicorn main:app --reload --host 0.0.0.0 --port 8080"
echo ""
echo "API will be available at: http://localhost:8080"
echo "API docs will be at: http://localhost:8080/api/docs"
