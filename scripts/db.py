#!/usr/bin/env python3
"""Apply SQL files to the Supabase Postgres database.

Usage:
  scripts/db.py supabase/migrations/0001_init.sql [more.sql ...]
  scripts/db.py --query "select count(*) from students"

Credentials come from $HOME/.secrets/supabase.env (never from the repo).
Tries the direct host first, then the session pooler in common regions.
"""
import os
import sys
from pathlib import Path

try:
    import psycopg
except ImportError:
    sys.exit("pip install 'psycopg[binary]'")

ENV = Path(os.environ.get("SUPABASE_ENV_FILE", Path.home() / ".secrets" / "supabase.env"))


def load_env():
    env = {}
    for line in ENV.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        env[k.strip()] = v.strip().strip("'\"")
    return env


def candidates(env):
    pid = env["SUPABASE_PROJECT_ID"]
    pw = env["SUPABASE_DB_PASSWORD"]
    yield f"host=db.{pid}.supabase.co port=5432 dbname=postgres user=postgres password={pw} sslmode=require"
    for region in ["eu-west-1", "eu-central-1", "eu-west-2", "us-east-1", "us-east-2", "us-west-1", "ap-south-1", "ap-southeast-1", "af-south-1", "sa-east-1", "eu-north-1", "ap-northeast-1"]:
        yield f"host=aws-0-{region}.pooler.supabase.com port=5432 dbname=postgres user=postgres.{pid} password={pw} sslmode=require"
        yield f"host=aws-1-{region}.pooler.supabase.com port=5432 dbname=postgres user=postgres.{pid} password={pw} sslmode=require"


def connect(env):
    last = None
    for dsn in candidates(env):
        host = dsn.split()[0]
        try:
            conn = psycopg.connect(dsn, connect_timeout=8, autocommit=False)
            print(f"connected via {host.split('=')[1]}")
            return conn
        except Exception as e:  # noqa: BLE001
            last = e
    sys.exit(f"could not connect: {last}")


def main():
    env = load_env()
    conn = connect(env)
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    if args[0] == "--query":
        with conn.cursor() as cur:
            cur.execute(args[1])
            if cur.description:
                for row in cur.fetchall():
                    print(row)
            else:
                print(cur.statusmessage)
        conn.commit()
        conn.close()
        return
    for f in args:
        sql = Path(f).read_text()
        print(f"--- applying {f} ({len(sql)} bytes)")
        try:
            with conn.cursor() as cur:
                cur.execute(sql)
            conn.commit()
            print(f"    ok")
        except Exception as e:  # noqa: BLE001
            conn.rollback()
            sys.exit(f"    FAILED: {e}")
    conn.close()


if __name__ == "__main__":
    main()
