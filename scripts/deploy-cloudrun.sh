#!/usr/bin/env bash
# ============================================================
# GeoDisha POC — Cloud Run Deploy Script
# GCP Project: geo-pulse-463507
# Region:      asia-south1
# ============================================================
set -e

PROJECT="geo-pulse-463507"
REGION="asia-south1"
API_SERVICE="geodisha-api"
WEB_SERVICE="geodisha-web"

echo "🚀 Deploying GeoDisha POC to Cloud Run..."
echo "   Project : $PROJECT"
echo "   Region  : $REGION"

# ── 1. Deploy Backend API ─────────────────────────────────
echo ""
echo "▶ Step 1/3 — Deploying backend API..."
cd "$(dirname "$0")/backend"
gcloud run deploy $API_SERVICE \
  --source . \
  --region "$REGION" \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 2 \
  --project "$PROJECT"

API_URL=$(gcloud run services describe $API_SERVICE \
  --region "$REGION" --project "$PROJECT" \
  --format "value(status.url)")
echo "✅ API deployed at: $API_URL"

# ── 2. Patch Flutter baseUrl ──────────────────────────────
echo ""
echo "▶ Step 2/3 — Patching Flutter API base URL..."
ENDPOINTS_FILE="../mobile/lib/core/constants/api_endpoints.dart"
sed -i.bak "s|static const String baseUrl = '.*'|static const String baseUrl = '$API_URL'|" "$ENDPOINTS_FILE"
echo "   baseUrl set to: $API_URL"

# ── 3. Build & Deploy Flutter Web ────────────────────────
echo ""
echo "▶ Step 3/3 — Building Flutter web and deploying..."
cd "$(dirname "$0")/mobile"
flutter pub get
flutter build web --release --base-href /

gcloud run deploy $WEB_SERVICE \
  --source . \
  --region "$REGION" \
  --allow-unauthenticated \
  --port 8080 \
  --memory 256Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 2 \
  --project "$PROJECT"

WEB_URL=$(gcloud run services describe $WEB_SERVICE \
  --region "$REGION" --project "$PROJECT" \
  --format "value(status.url)")

# ── Restore local baseUrl ─────────────────────────────────
sed -i.bak "s|static const String baseUrl = '.*'|static const String baseUrl = 'http://localhost:8000'|" "$ENDPOINTS_FILE"
rm -f "$ENDPOINTS_FILE.bak" "../backend/$ENDPOINTS_FILE.bak" 2>/dev/null || true

echo ""
echo "=============================================="
echo "✅ GeoDisha POC deployed!"
echo "   🌐 Web App : $WEB_URL"
echo "   🔌 API     : $API_URL"
echo "   🔑 Login   : admin@geodisha.com / admin123"
echo "=============================================="
