# GeoDisha Political Intelligence Platform — POC Overview

> **Version**: 1.0.0 (POC with Synthetic Seed Data)  
> **Stack**: Flutter Web + FastAPI Mock Backend  
> **Audience**: Client presentation, developer handover  
> **Last Updated**: May 2026

---

## Table of Contents

1. [What is GeoDisha?](#1-what-is-geodisha)
2. [Architecture Overview](#2-architecture-overview)
3. [User Roles & Access](#3-user-roles--access)
4. [Modules & Features](#4-modules--features)
5. [Screen Inventory](#5-screen-inventory)
6. [Seed Data Files](#6-seed-data-files)
7. [API Endpoints](#7-api-endpoints)
8. [Running Locally](#8-running-locally)
9. [Deployment](#9-deployment)
10. [Technology Stack](#10-technology-stack)
11. [Future Roadmap](#11-future-roadmap)

---

## 1. What is GeoDisha?

**GeoDisha** is a comprehensive **Political Intelligence & Constituency Management Platform** designed for elected representatives — MLAs, MPs, and Ministers — and their field teams.

The platform provides:
- **Real-time constituency health monitoring** — voter sentiment, active issues, crisis alerts
- **AI-powered recommendations** — who to visit, what to say, where to focus
- **Election intelligence** — booth-level analytics, swing voter mapping, opposition tracking
- **Promise & governance tracking** — delivery status, delayed commitments, beneficiary counts
- **Ground reality visibility** — ward coverage, field visit records, issue heatmaps

This POC uses **fully synthetic seed data** representing a fictional constituency network (17 constituencies, ~46,000 data rows) to demonstrate all platform capabilities without requiring a live BigQuery or GCP connection.

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Web App                       │
│         (Material Design 3, Google Fonts / Inter)        │
│                                                          │
│  Dashboard → 8 Feature Modules → Detail Screens         │
└────────────────────────┬────────────────────────────────┘
                         │ HTTP (Dio)
                         │ localhost:8000  (dev)
                         │ Cloud Run URL   (prod)
┌────────────────────────▼────────────────────────────────┐
│              FastAPI Mock Server (Python)                 │
│                                                          │
│  • Loads 24 CSV seed files into memory at startup        │
│  • Exposes 40+ REST endpoints under /api/v1/             │
│  • CORS wide-open (suitable for POC)                     │
│  • No database required — pure in-memory serving         │
└─────────────────────────────────────────────────────────┘
```

### Production Target Architecture (Post-POC)

```
Flutter App (iOS / Android / Web)
        │
   Cloud Run (API Gateway — FastAPI)
        │
   BigQuery ──── Vertex AI (ML recommendations)
        │
   Firestore (real-time alerts, user profiles)
        │
   Firebase Auth (login / MFA)
```

---

## 3. User Roles & Access

| Role | Description | Special Capabilities |
|---|---|---|
| **Admin** | MLA / MP / Minister or campaign manager | Constituency switcher — can view any of the 17 constituencies; sees all modules |
| **Volunteer** | Field worker / party volunteer | Locked to assigned constituency; limited write access |

### Login Credentials (POC)

| Role | Username | Password |
|---|---|---|
| Admin | `admin@geodisha.com` | `admin123` |
| Volunteer | `volunteer@geodisha.com` | `volunteer123` |

> Authentication in the POC is a local mock — no Firebase connection required.

### Role-Based Differences
- **Admin** sees the constituency dropdown in the dashboard header — can switch between all 17 constituencies
- **Volunteer** sees a fixed constituency label
- Both roles access all 8 modules (full feature parity in this POC)

---

## 4. Modules & Features

### Module 1 — Command Center 🏛️
**Purpose**: Central KPI dashboard for constituency health

| Feature | Description |
|---|---|
| Health Score | Composite constituency wellness score (0–100) |
| Satisfaction Rate | Voter satisfaction percentage |
| Promise Completion Rate | % promises delivered vs pending |
| Active Issues | Count of open issues with critical flag |
| KPI Trends | Time-series chart of all key metrics |
| Executive Summary | AI-generated narrative summary per constituency |
| Trends Summary | Month-over-month performance comparison |

---

### Module 2 — AI Intelligence Hub 🧠
**Purpose**: AI-driven recommendations and media intelligence

| Feature | Description |
|---|---|
| AI Recommendations | Prioritised action cards (visit, message, escalate) with confidence scores |
| Media Briefing | Talking points auto-generated per constituency — what to say to media |
| Influencer Map | Key community influencers with reach, relationship strength, and sentiment |
| Visit Priority List | AI-ranked list of wards/areas to visit next, with ROI score |

---

### Module 3 — Ground Reality 🗺️
**Purpose**: Field visit visibility and issue heatmap

| Feature | Description |
|---|---|
| Visit Records | All field visits with date, location, purpose, outcome |
| Issue Heatmap | Ward-level issue density — colour-coded by severity |
| Ward Coverage | % of wards visited in current period |
| Visit Trends | Monthly visit frequency chart |
| Visit Statistics | Aggregate stats — total visits, avg per month, top wards |

---

### Module 4 — Election War Room 🗳️
**Purpose**: Booth-level election analytics and readiness

| Feature | Description |
|---|---|
| Booth Scores | Score (0–100) for every polling booth — security, turnout prediction, swing risk |
| Election Readiness | Overall readiness % with booth breakdown (Secure / Vulnerable / Critical) |
| Booth Risk Matrix | Top-risk booths with ward, score, and risk level |
| Swing Analysis | Swing voter identification by ward and demographic |
| Booth Score Trends | Historical trend of booth scores |

---

### Module 5 — Promise Tracker ✅
**Purpose**: Track every promise made to constituents

| Feature | Description |
|---|---|
| Promises Dashboard | All promises with status (Completed / In Progress / Delayed / Pending) |
| Overdue Promises | Promises past due date — sortable by delay severity |
| By Category | Promises grouped by sector (Infrastructure, Health, Education, etc.) |
| Completion Rate | Overall and category-wise delivery rate |
| Promise Updates | Timeline of updates/activities per promise |
| Beneficiaries | Count of citizens benefiting per promise |
| Milestones | Sub-task tracking for large promises |

---

### Module 6 — Alerts & Crisis Center 🚨
**Purpose**: Real-time alert management and crisis tracking

| Feature | Description |
|---|---|
| Active Alerts | All open alerts with severity (Critical / High / Medium / Low) |
| Alert Statistics | Category-wise and trend breakdown |
| Crisis Dashboard | Active crises with response timelines |
| Resolution Metrics | Avg resolution time, escalation rate, on-time % |
| Issue Escalations | Escalated grievances requiring immediate attention |

---

### Module 7 — Political Intelligence 🏴
**Purpose**: Opposition tracking and voter segment analysis

| Feature | Description |
|---|---|
| Voter Segments | Demographic/psychographic voter groups — size, loyalty, engagement, support level |
| Support Level Breakdown | Strong Favorable / Leaning / Undecided / Opposition counts per segment |
| Opposition Intelligence | Competitor candidate profiles — attack lines, strong areas, counter-strategy |
| Target Messaging | AI-generated message per voter segment |
| Top Issues per Segment | Issues most important to each voter group |

---

### Module 8 — Constituency Pulse 📊
**Purpose**: Deep-dive constituency health with 3 tabs

#### Tab 1: Ward Intelligence
- All wards with health score, risk level, attention flag
- Filter by risk level (All / Critical / High / Medium / Low)
- Metrics: visitor count, issue count, satisfaction, promise delivery

#### Tab 2: Monitoring
- Live alert counts (Total Active, Critical, High, Medium, New 24h, Resolved 24h)
- Health scores across dimensions
- Response performance (avg response time, resolution time, escalation rate)
- Crisis status (active, resolved, new in 7 days)
- Alerts by category (bar chart)
- Hotspot wards (highest alert concentration)

#### Tab 3: KPI Trends
- Time-series charts for all key metrics per constituency
- Grouped by metric name
- Filterable by time range

---

### Additional Screens

| Screen | Description |
|---|---|
| **Dashboard** | Main landing with hero header, KPI pills, module grid, AI nudge card, recent alerts |
| **Executive Overview** | High-level constituency comparison across all 17 constituencies |
| **Strategic Intelligence** | Long-term trend analysis and strategic recommendations |
| **Analytics Dashboard** | Consolidated analytics view |
| **Constituency Heatmap** | Geographic issue heatmap visualisation |
| **Today's Focus** | Daily AI-curated action list |
| **Raise Alert** | Form to raise a new alert/grievance |
| **Profile & Settings** | User profile, notifications, preferences, sign out |

---

## 5. Screen Inventory

| Screen File | Module | Description |
|---|---|---|
| `dashboard_screen_new.dart` | Core | Main dashboard — hero header, KPIs, module grid |
| `command_center_screen.dart` | Module 1 | KPI trends and executive summary |
| `ai_intelligence_hub_screen.dart` | Module 2 | AI recommendations, media briefing, influencer map |
| `ground_reality_screen.dart` | Module 3 | Visits, heatmap, ward coverage |
| `election_war_room_screen.dart` | Module 4 | Booth scores, readiness, risk matrix |
| `promise_tracker_screen.dart` | Module 5 | Promises dashboard, overdue, categories |
| `alerts_center_screen.dart` | Module 6 | Active alerts, crisis dashboard |
| `political_intelligence_screen.dart` | Module 7 | Voter segments, opposition intel |
| `constituency_pulse_screen.dart` | Module 8 | Ward intel, monitoring, KPI trends |
| `executive_overview_screen.dart` | Overview | Cross-constituency comparison |
| `booth_score_screen.dart` | Module 4 | Detailed booth score analytics |
| `constituency_heatmap_screen.dart` | Module 3 | Geographic heatmap |
| `strategic_intelligence_screen.dart` | Analytics | Strategic recommendations |
| `media_ai_screen.dart` | Module 2 | Media talking points detail |
| `recommendations_screen.dart` | Module 2 | AI recommendations detail |
| `todays_focus_screen.dart` | Core | Daily action list |
| `raise_alert_screen.dart` | Module 6 | New alert form |
| `visits_list_screen_enhanced.dart` | Module 3 | Visit records list |
| `auth/login_screen.dart` | Auth | Login with role selection |
| `splash_screen.dart` | Core | Animated splash screen |

---

## 6. Seed Data Files

All data is synthetic and loaded from CSV files at server startup. **46,020 total rows** across 24 files.

| # | File | Rows | Description |
|---|---|---|---|
| 01 | `01_constituency_overview.csv` | 17 | One row per constituency — health score, satisfaction, risk level, active issues |
| 02 | `02_constituency_kpis.csv` | 6,205 | KPI time-series — metric name, value, date, constituency |
| 03 | `03_constituency_trends.csv` | 1,020 | Month-over-month trend data |
| 04 | `04_executive_summary.csv` | 204 | AI-generated narrative summaries (12 per constituency) |
| 05 | `05_ai_recommendations.csv` | 397 | AI action cards — type, priority, confidence, rationale |
| 06 | `06_media_talking_points.csv` | 265 | Media briefing points per constituency |
| 07 | `07_influencer_mapping.csv` | 752 | Influencer profiles — reach, platform, sentiment, relationship |
| 08 | `08_visit_planning.csv` | 349 | AI-ranked visit priority list per ward |
| 09 | `09_visit_records_enhanced.csv` | 4,986 | Historical field visits with outcome data |
| 10 | `10_issue_heatmap.csv` | 6,307 | Ward-level issue density with category and severity |
| 11 | `11_ward_intelligence.csv` | 1,428 | Ward health scores, risk levels, attention flags |
| 12 | `12_visit_statistics.csv` | 204 | Aggregate visit stats per constituency |
| 13 | `13_booth_analysis.csv` | 3,385 | Booth-level scores, risk classification, swing % |
| 14 | `14_booth_score_trends.csv` | 8,256 | Historical booth score trend data |
| 15 | `15_voter_segments.csv` | 172 | Voter segment profiles — demographics, support breakdown, top issues |
| 16 | `16_opposition_intelligence.csv` | 215 | Opposition candidate profiles and strategy data |
| 17 | `17_promises.csv` | 592 | All promises with status, category, deadline, department |
| 18 | `18_promise_updates.csv` | 669 | Activity log per promise |
| 19 | `19_promise_milestones.csv` | 342 | Sub-task milestones per promise |
| 20 | `20_promise_beneficiaries.csv` | 269 | Beneficiary counts per promise |
| 21 | `21_alerts.csv` | 2,705 | Alerts with severity, category, status, resolution time |
| 22 | `22_crisis_events.csv` | 91 | Crisis events with type, response timeline, status |
| 23 | `23_issue_escalations.csv` | 961 | Escalated grievances with department and priority |
| 24 | `24_monitoring_metrics.csv` | 6,205 | Monitoring KPIs — alert counts, health scores, response performance |

---

## 7. API Endpoints

Base URL: `http://localhost:8000/api/v1` (local) or `<CLOUD_RUN_URL>/api/v1` (deployed)

### Command Center
| Method | Endpoint | Description |
|---|---|---|
| GET | `/command-center/overview` | Constituency health overview |
| GET | `/command-center/kpi-trends` | KPI time-series |
| GET | `/command-center/executive-summary` | AI narrative summary |
| GET | `/command-center/trends-summary` | Month-over-month trends |

### AI Intelligence
| Method | Endpoint | Description |
|---|---|---|
| GET | `/ai-intelligence/recommendations` | AI action recommendations |
| GET | `/ai-intelligence/media-briefing` | Media talking points |
| GET | `/ai-intelligence/influencer-map` | Influencer profiles |
| GET | `/ai-intelligence/visit-priority-list` | Visit priority ranking |

### Ground Reality
| Method | Endpoint | Description |
|---|---|---|
| GET | `/ground-reality/visits` | Visit records |
| GET | `/ground-reality/heatmap` | Issue heatmap |
| GET | `/ground-reality/ward-coverage` | Ward coverage % |
| GET | `/ground-reality/visit-trends` | Visit frequency trends |
| GET | `/ground-reality/ward-intelligence` | Ward health details |

### Election War Room
| Method | Endpoint | Description |
|---|---|---|
| GET | `/election-war-room/booth-scores` | Booth score list |
| GET | `/election-war-room/readiness` | Election readiness summary |
| GET | `/election-war-room/risk-matrix` | Booth risk classification |
| GET | `/election-war-room/swing-analysis` | Swing voter analysis |

### Promises
| Method | Endpoint | Description |
|---|---|---|
| GET | `/promises/dashboard` | Promises with status |
| GET | `/promises/overdue` | Overdue promises |
| GET | `/promises/by-category` | Category breakdown |
| GET | `/promises/completion-rate` | Delivery rate |

### Alerts & Crisis
| Method | Endpoint | Description |
|---|---|---|
| GET | `/alerts/active` | Active alerts |
| GET | `/alerts/statistics` | Alert category stats |
| GET | `/alerts/crisis-dashboard` | Crisis events |
| GET | `/alerts/resolution-metrics` | Response performance |

### Intelligence Service Endpoints
| Method | Endpoint | Description |
|---|---|---|
| GET | `/voter-segments` | Voter segment profiles |
| GET | `/opposition-intelligence` | Opposition data |
| GET | `/monitoring/latest` | Latest monitoring snapshot |
| GET | `/monitoring/metrics` | Monitoring time-series |
| GET | `/booth-scores` | Booth score list |
| GET | `/executive-summary` | Executive summaries |
| GET | `/ground-reality/ward-intelligence` | Ward details |
| GET | `/constituency/kpis` | Constituency KPI data |

---

## 8. Running Locally

### Prerequisites
- Python 3.11+
- Flutter SDK 3.x
- Chrome browser

### Step 1: Start the Backend

```bash
cd geodisha-mobile-app/backend
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install fastapi uvicorn pandas
python mock_server.py
# → Server running at http://0.0.0.0:8000
# → Health check: http://localhost:8000/health
```

### Step 2: Run the Flutter Web App

```bash
cd geodisha-mobile-app/mobile
flutter pub get
flutter run -d chrome --web-port 3000
# → App opens at http://localhost:3000
```

### Step 3: Login
- Use `admin@geodisha.com` / `admin123` for full admin access
- Use `volunteer@geodisha.com` / `volunteer123` for volunteer view

---

## 9. Deployment

### Option A: Cloud Run (Recommended — GCP project `geo-pulse-463507`)

Both the Flutter web app (as static files) and the FastAPI backend are deployed as separate Cloud Run services.

#### Deploy Backend
```bash
cd geodisha-mobile-app/backend
gcloud run deploy geodisha-api \
  --source . \
  --region asia-south1 \
  --allow-unauthenticated \
  --project geo-pulse-463507
```

#### Deploy Flutter Web Frontend
```bash
cd geodisha-mobile-app/mobile
flutter build web --release --base-href /
gcloud run deploy geodisha-web \
  --source . \
  --region asia-south1 \
  --allow-unauthenticated \
  --project geo-pulse-463507
```

> Update `ApiEndpoints.baseUrl` in `mobile/lib/core/constants/api_endpoints.dart` to the Cloud Run API URL before building.

---

## 10. Technology Stack

### Frontend
| Technology | Version | Purpose |
|---|---|---|
| Flutter | 3.x | Cross-platform UI framework |
| Dart | 3.x | Programming language |
| Material Design 3 | — | Design system |
| Google Fonts (Inter) | ^8.1 | Typography |
| Dio | ^5.4 | HTTP client |
| fl_chart | ^0.65 | Charts and graphs |
| animate_do | ^3.3 | Animations |
| flutter_screenutil | ^5.9 | Responsive sizing |

### Backend (POC)
| Technology | Version | Purpose |
|---|---|---|
| Python | 3.11+ | Runtime |
| FastAPI | Latest | REST API framework |
| Uvicorn | Latest | ASGI server |
| Pandas | Latest | CSV seed data loading |

### Deployment
| Service | Purpose |
|---|---|
| Google Cloud Run | Serverless container hosting |
| Google Cloud Build | CI/CD pipeline |
| GitHub | Source control |

---

## 11. Future Roadmap

| Phase | Feature | Priority |
|---|---|---|
| Phase 2 | Connect to live BigQuery — replace seed CSVs | 🔴 High |
| Phase 2 | Firebase Authentication (real login/MFA) | 🔴 High |
| Phase 2 | Push notifications via Firebase Cloud Messaging | 🟡 Medium |
| Phase 3 | Native iOS & Android builds | 🟡 Medium |
| Phase 3 | Vertex AI integration (real ML recommendations) | 🟡 Medium |
| Phase 3 | Offline mode with local SQLite caching | 🟢 Low |
| Phase 4 | Multi-language support (Hindi, regional languages) | 🟢 Low |
| Phase 4 | Role-based write access (raise alerts, log visits) | 🟡 Medium |
| Phase 4 | WhatsApp integration for alert notifications | 🟢 Low |

---

## Project Structure

```
geodisha-mobile-app/
├── mobile/                          # Flutter application
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/           # API endpoints
│   │   │   ├── services/            # ApiService (Dio HTTP client)
│   │   │   └── theme/               # AppTheme (colors, typography, gradients)
│   │   ├── data/
│   │   │   └── services/            # Domain services (one per module)
│   │   └── presentation/
│   │       ├── screens/             # 20+ screens
│   │       └── widgets/             # Shared widget library (gd_widgets.dart)
│   ├── assets/                      # Logo, images
│   └── pubspec.yaml
│
├── backend/
│   ├── mock_server.py               # ⭐ Main POC backend — run this
│   ├── sql/seed/                    # 24 CSV seed data files (46,020 rows)
│   ├── api-gateway/                 # Full production FastAPI (for post-POC)
│   └── services/                    # Microservice stubs
│
├── infrastructure/                  # Terraform IaC (post-POC)
├── ml-models/                       # ML model stubs (post-POC)
├── sql/                             # BigQuery schema & views (post-POC)
├── scripts/                         # GCP deployment scripts
├── START.sh                         # One-command local startup
└── GEODISHA_POC_OVERVIEW.md         # ← This document
```

---

*GeoDisha POC — Built for client demonstration with synthetic data. All constituency names, voter counts, and political data are entirely fictional.*
