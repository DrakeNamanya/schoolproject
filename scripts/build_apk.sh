#!/usr/bin/env bash
# Release APK wired to Supabase.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh
flutter build apk --release $DART_DEFINES "$@"
