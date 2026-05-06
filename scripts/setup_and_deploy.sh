#!/bin/bash

# GeoDisha Mobile App - Complete Setup and Deployment Script
set -e

echo "🚀 GeoDisha Mobile App - Setup & Deployment"
echo "============================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID=${GCP_PROJECT_ID:-""}
REGION=${GCP_REGION:-"asia-south1"}
ENVIRONMENT=${ENVIRONMENT:-"development"}

# Function to print colored output
print_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check gcloud
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI not found. Please install Google Cloud SDK."
        exit 1
    fi
    
    # Check terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform not found. Please install Terraform."
        exit 1
    fi
    
    # Check python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 not found. Please install Python 3.11+."
        exit 1
    fi
    
    # Check flutter
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter not found. Please install Flutter SDK."
        exit 1
    fi
    
    print_info "✅ All prerequisites met!"
}

# Setup GCP project
setup_gcp() {
    print_info "Setting up Google Cloud Platform..."
    
    if [ -z "$PROJECT_ID" ]; then
        print_error "GCP_PROJECT_ID not set. Please set it and try again."
        exit 1
    fi
    
    # Set project
    gcloud config set project $PROJECT_ID
    
    # Enable required APIs
    print_info "Enabling required APIs..."
    gcloud services enable \
        run.googleapis.com \
        firestore.googleapis.com \
        sqladmin.googleapis.com \
        bigquery.googleapis.com \
        storage.googleapis.com \
        cloudfunctions.googleapis.com \
        pubsub.googleapis.com \
        aiplatform.googleapis.com \
        secretmanager.googleapis.com \
        firebase.googleapis.com \
        artifactregistry.googleapis.com \
        cloudbuild.googleapis.com
    
    print_info "✅ GCP setup complete!"
}

# Deploy infrastructure
deploy_infrastructure() {
    print_info "Deploying infrastructure with Terraform..."
    
    cd infrastructure/terraform
    
    # Initialize Terraform
    terraform init
    
    # Create terraform.tfvars if it doesn't exist
    if [ ! -f terraform.tfvars ]; then
        print_warning "terraform.tfvars not found. Creating from example..."
        cat > terraform.tfvars <<EOF
project_id = "$PROJECT_ID"
region = "$REGION"
environment = "$ENVIRONMENT"
db_password = "$(openssl rand -base64 32)"
EOF
    fi
    
    # Plan and apply
    terraform plan -out=tfplan
    terraform apply tfplan
    
    cd ../..
    
    print_info "✅ Infrastructure deployed!"
}

# Setup backend
setup_backend() {
    print_info "Setting up backend services..."
    
    cd backend/api-gateway
    
    # Copy .env.example to .env if it doesn't exist
    if [ ! -f .env ]; then
        cp .env.example .env
        print_warning "Created .env file. Please configure it with your settings."
    fi
    
    # Install Python dependencies
    print_info "Installing Python dependencies..."
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    
    cd ../..
    
    print_info "✅ Backend setup complete!"
}

# Deploy backend to Cloud Run
deploy_backend() {
    print_info "Deploying backend to Cloud Run..."
    
    cd backend/api-gateway
    
    # Make deploy script executable
    chmod +x deploy.sh
    
    # Deploy
    ./deploy.sh
    
    cd ../..
    
    print_info "✅ Backend deployed!"
}

# Setup mobile app
setup_mobile() {
    print_info "Setting up Flutter mobile app..."
    
    cd mobile
    
    # Get Flutter dependencies
    flutter pub get
    
    # Run code generation
    flutter pub run build_runner build --delete-conflicting-outputs
    
    cd ..
    
    print_info "✅ Mobile app setup complete!"
}

# Run tests
run_tests() {
    print_info "Running tests..."
    
    # Backend tests
    cd backend/api-gateway
    source venv/bin/activate
    pytest tests/ -v
    cd ../..
    
    # Mobile tests
    cd mobile
    flutter test
    cd ..
    
    print_info "✅ Tests completed!"
}

# Main menu
show_menu() {
    echo ""
    echo "What would you like to do?"
    echo "1) Full setup (infrastructure + backend + mobile)"
    echo "2) Setup infrastructure only"
    echo "3) Deploy backend only"
    echo "4) Setup mobile app only"
    echo "5) Run tests"
    echo "6) Exit"
    echo ""
    read -p "Enter your choice [1-6]: " choice
    
    case $choice in
        1)
            check_prerequisites
            setup_gcp
            deploy_infrastructure
            setup_backend
            deploy_backend
            setup_mobile
            print_info "🎉 Full setup complete!"
            ;;
        2)
            check_prerequisites
            setup_gcp
            deploy_infrastructure
            ;;
        3)
            check_prerequisites
            setup_backend
            deploy_backend
            ;;
        4)
            check_prerequisites
            setup_mobile
            ;;
        5)
            run_tests
            ;;
        6)
            print_info "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            show_menu
            ;;
    esac
}

# Run main menu
show_menu
