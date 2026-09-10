#!/usr/bin/env bash
set -e

echo "=================================================="
echo " VIAN ERP — Flutter Web Production Build (Vercel)"
echo "=================================================="

# Detect Flutter SDK or install it if missing in Vercel build environment
if ! command -v flutter &> /dev/null; then
  echo "[1/4] Flutter not found in PATH. Installing Flutter stable SDK..."
  FLUTTER_DIR="$HOME/flutter"
  if [ ! -d "$FLUTTER_DIR" ]; then
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
  fi
  export PATH="$FLUTTER_DIR/bin:$PATH"
fi

echo "[2/4] Flutter SDK diagnostics:"
flutter --version

# Ensure working directory is apps/flutter_web
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "[3/4] Resolving Flutter dependencies..."
flutter pub get

API_URL="${API_URL:-https://vian-erp-api.onrender.com/api}"
echo "[4/4] Compiling Flutter Web bundle (Release mode)..."
echo "Targeting Production API: $API_URL"

flutter build web --release \
  --dart-define=API_URL="$API_URL" \
  --dart-define=ENABLE_DEMO_LOGIN=false \
  --dart-define=ENVIRONMENT=production

echo "=================================================="
echo " Build successful: build/web ready for deployment"
echo "=================================================="
