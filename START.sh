#!/bin/zsh
# GeoDisha — Start everything
# Usage: ./START.sh

ROOT="$(cd "$(dirname "$0")" && pwd)"
BACKEND="$ROOT/backend"
MOBILE="$ROOT/mobile"
VENV="$BACKEND/.venv"

echo "🚀 GeoDisha Startup"
echo "==================="

# ── 1. Start mock backend ──────────────────────────────────────────
echo "\n📡 Starting Mock API Backend on http://localhost:8000 ..."
source "$VENV/bin/activate"
cd "$BACKEND"
python mock_server.py &
BACKEND_PID=$!
echo "   Backend PID: $BACKEND_PID"

# Wait for it to be ready
sleep 3
echo "   ✅ Backend ready — API docs: http://localhost:8000/api/docs"

# ── 2. Start Flutter web ───────────────────────────────────────────
echo "\n📱 Starting Flutter Web on http://localhost:8080 ..."
cd "$MOBILE"
flutter run -d chrome --web-port=8080 &
FLUTTER_PID=$!
echo "   Flutter PID: $FLUTTER_PID"

echo "\n==================="
echo "✅ All systems go!"
echo "   🌐 App:     http://localhost:8080"
echo "   📡 API:     http://localhost:8000"
echo "   📖 Docs:    http://localhost:8000/api/docs"
echo "==================="
echo "Press Ctrl+C to stop all services"

# Keep running, kill both on exit
trap "kill $BACKEND_PID $FLUTTER_PID 2>/dev/null; echo '\n👋 Stopped all services'" SIGINT SIGTERM
wait
