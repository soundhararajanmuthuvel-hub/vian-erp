#!/usr/bin/env bash
set -e

echo "=================================================="
echo " VIAN ERP — Vercel Flutter Web Production Build"
echo "=================================================="

# Detect Flutter SDK or install it if missing in Vercel environment
if ! command -v flutter &> /dev/null; then
  echo "[1/4] Flutter not found. Installing Flutter stable SDK..."
  FLUTTER_DIR="$HOME/flutter"
  if [ ! -d "$FLUTTER_DIR" ]; then
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
  fi
  export PATH="$FLUTTER_DIR/bin:$PATH"
fi

echo "[2/4] Flutter SDK diagnostics:"
flutter --version

# Navigate to Flutter Web app directory
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR/apps/flutter_web"

echo "[3/4] Resolving dependencies..."
flutter pub get

API_URL="${API_URL:-https://vian-erp-api.onrender.com/api}"
echo "[4/4] Building Flutter Web bundle (Release mode)..."
echo "Targeting API: $API_URL"

flutter build web --release \
  --dart-define=API_URL="$API_URL" \
  --dart-define=ENABLE_DEMO_LOGIN=false \
  --dart-define=ENVIRONMENT=production

echo "=================================================="
echo " Flutter Web build complete: apps/flutter_web/build/web"
echo "=================================================="
