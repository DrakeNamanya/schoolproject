#!/usr/bin/env bash
# Netlify build: install pinned Flutter, build web with Supabase credentials from env vars.
set -euo pipefail
: "${SUPABASE_URL:?Set SUPABASE_URL in Netlify environment variables}"
: "${SUPABASE_ANON_KEY:?Set SUPABASE_ANON_KEY in Netlify environment variables}"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.35.4}"
if [ ! -d "$HOME/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$HOME/flutter"
fi
export PATH="$HOME/flutter/bin:$PATH"
flutter --version
flutter config --no-analytics --enable-web >/dev/null
flutter pub get
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=flutter.inspector.structuredErrors=false
