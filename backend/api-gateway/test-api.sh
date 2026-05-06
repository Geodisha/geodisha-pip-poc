#!/bin/bash

# GeoDisha API - Complete Test Script
# Tests all BigQuery-connected endpoints

set -e

API_URL="http://localhost:8080"

echo "🧪 GeoDisha API - Complete Test Suite"
echo "====================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to test endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local description=$3
    
    echo -n "Testing: $description ... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" -X $method "$API_URL$endpoint")
    
    if [ $response -eq 200 ] || [ $response -eq 201 ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $response)"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC} (HTTP $response)"
        return 1
    fi
}

# Check if API is running
echo "1️⃣  Checking if API is running..."
if ! curl -s "$API_URL/health" > /dev/null; then
    echo -e "${RED}❌ API is not running!${NC}"
    echo ""
    echo "Please start the API first:"
    echo "  cd backend/api-gateway"
    echo "  ./start-dev.sh"
    exit 1
fi
echo -e "${GREEN}✓ API is running${NC}"
echo ""

# Test Health Check
echo "2️⃣  Testing Health Endpoints..."
test_endpoint "GET" "/health" "Health check"
test_endpoint "GET" "/" "Root endpoint"
echo ""

# Test Visits Endpoints (BigQuery)
echo "3️⃣  Testing Visits Endpoints (BigQuery)..."
test_endpoint "GET" "/api/v1/visits/" "Get all visits"
test_endpoint "GET" "/api/v1/visits/?limit=10" "Get visits with limit"
test_endpoint "GET" "/api/v1/visits/statistics" "Get visit statistics"
test_endpoint "GET" "/api/v1/visits/locations" "Get visits by location"
test_endpoint "GET" "/api/v1/visits/timeline" "Get visit timeline"
test_endpoint "GET" "/api/v1/visits/timeline?days=7" "Get 7-day timeline"
echo ""

# Test Search
echo "4️⃣  Testing Search Functionality..."
test_endpoint "GET" "/api/v1/visits/search?q=bhongir" "Search visits"
echo ""

# Test Constituencies Endpoints
echo "5️⃣  Testing Constituencies Endpoints..."
test_endpoint "GET" "/api/v1/constituencies/" "Get all constituencies"
echo ""

# Detailed Tests with Output
echo "6️⃣  Detailed Response Tests..."
echo ""

echo "📊 Visit Statistics:"
curl -s "$API_URL/api/v1/visits/statistics" | python3 -m json.tool || echo "Response received"
echo ""
echo ""

echo "📍 Top Locations:"
curl -s "$API_URL/api/v1/visits/locations?limit=5" | python3 -m json.tool || echo "Response received"
echo ""
echo ""

echo "🏛️ Constituencies:"
curl -s "$API_URL/api/v1/constituencies/" | python3 -m json.tool || echo "Response received"
echo ""
echo ""

# Performance Test
echo "7️⃣  Performance Test..."
echo "Testing response time for 10 requests..."

total_time=0
for i in {1..10}; do
    start=$(date +%s%N)
    curl -s "$API_URL/api/v1/visits/?limit=10" > /dev/null
    end=$(date +%s%N)
    elapsed=$((($end - $start) / 1000000))
    total_time=$(($total_time + $elapsed))
done

avg_time=$(($total_time / 10))
echo -e "${GREEN}Average response time: ${avg_time}ms${NC}"
echo ""

# Summary
echo "✅ Test Suite Complete!"
echo ""
echo "📝 Summary:"
echo "  - API Base URL: $API_URL"
echo "  - Interactive Docs: $API_URL/api/docs"
echo "  - Health Check: $API_URL/health"
echo ""
echo "🎯 Next Steps:"
echo "  1. Check the interactive docs at $API_URL/api/docs"
echo "  2. Test with your GCP project data"
echo "  3. Start building the mobile app"
echo ""
echo "💡 Pro Tip: Open $API_URL/api/docs in your browser for interactive testing"
