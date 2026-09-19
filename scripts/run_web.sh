#!/usr/bin/env bash
# Dev run in Chrome against Supabase.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh
flutter run -d chrome $DART_DEFINES "$@"
