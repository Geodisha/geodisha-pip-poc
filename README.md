# GeoDisha Political Intelligence Mobile Platform

A comprehensive political intelligence and governance platform for MLAs, MPs, and Ministers, built natively on Google Cloud Platform.

## 🎯 Platform Overview

GeoDisha enables:
- **Constituency Management**: Track citizen grievances, projects, and geo-tagged progress
- **Governance Tracking**: Monitor promises, commitments, and delivery status
- **Election Intelligence**: Booth-level analytics, voter mood tracking, and swing voter identification
- **AI-Driven Decisions**: Smart visit planning and messaging recommendations

## 🏗️ Architecture

### Technology Stack

#### Mobile Frontend
- **Framework**: Flutter (Cross-platform for iOS & Android)
- **State Management**: Riverpod/Bloc
- **UI**: Material Design 3
- **Maps**: Google Maps Flutter Plugin
- **Analytics**: Firebase Analytics
- **Push Notifications**: Firebase Cloud Messaging

#### Backend (Google Cloud Native)
- **API Gateway**: Cloud Run (Containerized FastAPI/Node.js)
- **Authentication**: Firebase Authentication + Identity Platform
- **Database**: 
  - Firestore (Real-time data, user profiles, grievances)
  - Cloud SQL (PostgreSQL - Structured data, voting analytics)
  - BigQuery (Data warehouse, analytics, ML features)
- **Storage**: Cloud Storage (Images, documents, media)
- **AI/ML**: Vertex AI (Custom models for predictions, recommendations)
- **Functions**: Cloud Functions (Event-driven processing)
- **Messaging**: Pub/Sub (Event streaming, notifications)
- **Search**: Algolia/Elasticsearch on GKE
- **CDN**: Cloud CDN
- **Monitoring**: Cloud Monitoring + Cloud Logging
- **Security**: Secret Manager, VPC, IAM

### Architecture Patterns
- **Microservices**: Separate services for each domain
- **Event-Driven**: Pub/Sub for async communication
- **CQRS**: Command Query Responsibility Segregation for analytics
- **API-First**: RESTful + GraphQL APIs
- **Serverless-First**: Cloud Run, Cloud Functions for scalability

## 📱 Core Modules

### 1. Constituency Management
- Citizen grievance tracking with geo-tagging
- Project monitoring dashboard
- Department-wise escalation workflows
- Real-time progress updates

### 2. Visit & Promise Management
- Historical visit memory
- Promise capture and tracking
- Automated reminders
- Risk alerts for non-delivery

### 3. Strategic Intelligence
- Smart visit planning with heatmaps
- Community drift detection
- High-ROI zone identification
- Media narrative intelligence

### 4. Election Intelligence
- Booth-level analytics
- Voter mood index
- Swing voter identification
- Turnout prediction models

### 5. AI Engines
- **"What Should I Say?" Engine**: Auto-generated statements
- **"Where Should I Go Next?" Engine**: Visit ROI rankings
- **Promise Risk Engine**: Delivery gap analysis
- **Booth Score Engine**: Historical + sentiment analysis

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Google Cloud SDK
- Node.js 18+ or Python 3.11+
- Docker & Docker Compose
- Firebase CLI

### Setup Instructions

1. **Clone and Setup**
   ```bash
   cd geodisha-mobile-app
   chmod +x scripts/setup.sh
   ./scripts/setup.sh
   ```

2. **Configure GCP**
   ```bash
   gcloud init
   gcloud config set project YOUR_PROJECT_ID
   ```

3. **Deploy Backend**
   ```bash
   cd backend
   ./deploy.sh
   ```

4. **Run Mobile App**
   ```bash
   cd mobile
   flutter pub get
   flutter run
   ```

## 📂 Project Structure

```
geodisha-mobile-app/
├── mobile/                 # Flutter mobile app
├── backend/               # Backend services
│   ├── api-gateway/      # Main API gateway
│   ├── services/         # Microservices
│   └── shared/           # Shared utilities
├── infrastructure/        # Terraform IaC
├── ml-models/            # ML model training & deployment
├── docs/                 # Documentation
└── scripts/              # Deployment & utility scripts
```

## 🔐 Security

- Firebase Authentication with MFA
- Row-level security in databases
- API key rotation
- Encrypted data at rest and in transit
- VPC for backend services
- IAM role-based access control

## 📊 Monitoring & Analytics

- Cloud Monitoring dashboards
- Real-time error tracking
- User behavior analytics
- Performance monitoring
- Cost tracking and optimization

## 🔄 CI/CD

- GitHub Actions / Cloud Build
- Automated testing
- Staging and production environments
- Blue-green deployments
- Rollback capabilities

## 📄 License

Proprietary - GeoDisha Platform

## 👥 Team

GeoDisha Development Team

---

**Version**: 1.0.0  
**Last Updated**: November 26, 2025
