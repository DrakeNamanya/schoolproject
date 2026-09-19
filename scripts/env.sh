#!/usr/bin/env bash
# Loads Supabase credentials from OUTSIDE the repo ($HOME/.secrets/supabase.env).
# Source this; never commit the env file.
set -a
source "${SUPABASE_ENV_FILE:-$HOME/.secrets/supabase.env}"
set +a
# Only the public pair is ever compiled into the Flutter app (JWT anon key works with PostgREST; publishable key is for newer SDK paths).
export DART_DEFINES="--dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
