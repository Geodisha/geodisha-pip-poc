# GeoDisha Mobile Platform - Infrastructure

This directory contains Terraform configurations for deploying the GeoDisha platform on Google Cloud Platform.

## Structure

```
infrastructure/
├── modules/           # Reusable Terraform modules
│   ├── networking/   # VPC, subnets, firewall rules
│   ├── cloud-run/    # Cloud Run services
│   ├── databases/    # Cloud SQL, Firestore
│   ├── storage/      # Cloud Storage buckets
│   ├── vertex-ai/    # ML infrastructure
│   └── monitoring/   # Logging, monitoring, alerts
├── environments/     # Environment-specific configs
│   ├── dev/
│   ├── staging/
│   └── production/
└── main.tf          # Root module
```

## Prerequisites

1. **Google Cloud SDK**
   ```bash
   curl https://sdk.cloud.google.com | bash
   gcloud init
   ```

2. **Terraform**
   ```bash
   brew install terraform  # macOS
   # or download from terraform.io
   ```

3. **GCP Project**
   - Create a new project in Google Cloud Console
   - Enable required APIs:
     ```bash
     gcloud services enable \
       compute.googleapis.com \
       run.googleapis.com \
       sqladmin.googleapis.com \
       storage-api.googleapis.com \
       aiplatform.googleapis.com \
       firestore.googleapis.com \
       cloudscheduler.googleapis.com \
       pubsub.googleapis.com
     ```

## Setup

1. **Configure GCP credentials**
   ```bash
   gcloud auth application-default login
   ```

2. **Set project variables**
   ```bash
   export PROJECT_ID="your-project-id"
   export REGION="us-central1"
   export ENVIRONMENT="dev"
   ```

3. **Initialize Terraform**
   ```bash
   cd environments/dev
   terraform init
   ```

4. **Plan deployment**
   ```bash
   terraform plan -var="project_id=${PROJECT_ID}" -var="region=${REGION}"
   ```

5. **Apply configuration**
   ```bash
   terraform apply -var="project_id=${PROJECT_ID}" -var="region=${REGION}"
   ```

## Modules

### Networking
- VPC network
- Subnets (public, private)
- Firewall rules
- Cloud NAT
- VPC peering

### Cloud Run
- Service deployments
- Traffic splitting
- Auto-scaling configuration
- Custom domains

### Databases
- Cloud SQL (PostgreSQL)
- Firestore configuration
- BigQuery datasets
- Cloud Memorystore (Redis)

### Storage
- Cloud Storage buckets
- Lifecycle policies
- IAM permissions

### Vertex AI
- Model endpoints
- Training jobs
- Feature store

### Monitoring
- Log sinks
- Monitoring dashboards
- Alert policies
- Uptime checks

## Best Practices

1. **State Management**
   - Use Cloud Storage backend for Terraform state
   - Enable state locking
   - Separate state per environment

2. **Security**
   - Use Secret Manager for sensitive data
   - Enable VPC Service Controls
   - Implement least privilege IAM
   - Enable audit logging

3. **Cost Optimization**
   - Use committed use discounts
   - Implement auto-scaling
   - Set up budget alerts
   - Regular resource cleanup

4. **Disaster Recovery**
   - Multi-region deployments
   - Automated backups
   - Point-in-time recovery
   - Regular DR drills

## Environment Management

### Development
- Single region deployment
- Minimal resources
- Relaxed security (within reason)
- Cost-optimized

### Staging
- Mirror production configuration
- Separate data isolation
- Full monitoring setup
- Testing environment

### Production
- Multi-region deployment
- High availability
- Full security controls
- Performance optimization

## Deployment Commands

```bash
# Development
cd environments/dev
terraform apply -auto-approve

# Staging
cd environments/staging
terraform apply

# Production (requires approval)
cd environments/production
terraform plan -out=tfplan
terraform apply tfplan
```

## Troubleshooting

### Common Issues

1. **API not enabled**
   ```bash
   gcloud services enable <api-name>
   ```

2. **Insufficient permissions**
   ```bash
   gcloud projects add-iam-policy-binding PROJECT_ID \
     --member=user:EMAIL \
     --role=roles/ROLE
   ```

3. **State lock issues**
   ```bash
   terraform force-unlock LOCK_ID
   ```

## Support

For issues or questions, contact the GeoDisha infrastructure team.
