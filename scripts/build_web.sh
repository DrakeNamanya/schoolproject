#!/usr/bin/env bash
# Release web build wired to Supabase.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh
flutter build web --release $DART_DEFINES --dart-define=flutter.inspector.structuredErrors=false "$@"
