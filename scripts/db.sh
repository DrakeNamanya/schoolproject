#!/usr/bin/env bash
# Apply a SQL file to the Supabase project via the Postgres connection.
# Usage: scripts/db.sh supabase/migrations/0001_init.sql
# Requires psql + SUPABASE_DB_PASSWORD in the env file (Project settings -> Database).
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh
: "${SUPABASE_DB_PASSWORD:?Add SUPABASE_DB_PASSWORD to $HOME/.secrets/supabase.env}"
psql "postgresql://postgres.${SUPABASE_PROJECT_ID}:${SUPABASE_DB_PASSWORD}@aws-0-eu-central-1.pooler.supabase.com:5432/postgres?sslmode=require" -v ON_ERROR_STOP=1 -f "$1"
