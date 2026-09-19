#!/usr/bin/env python3
"""Create demo auth users via the Supabase Auth Admin API and print their ids.

Uses the SERVICE ROLE key from $HOME/.secrets/supabase.env — server-side only.
Idempotent: existing users are looked up, not recreated.
"""
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

ENV = Path(os.environ.get("SUPABASE_ENV_FILE", Path.home() / ".secrets" / "supabase.env"))
env = {}
for line in ENV.read_text().splitlines():
    if "=" in line and not line.strip().startswith("#"):
        k, v = line.split("=", 1)
        env[k.strip()] = v.strip().strip("'\"")

URL = env["SUPABASE_URL"]
KEY = env["SUPABASE_SERVICE_ROLE_KEY"]
HDR = {"apikey": KEY, "Authorization": f"Bearer {KEY}", "Content-Type": "application/json"}

DEMO_PASSWORD = "Timbitwire2026!"

USERS = [
    # key,        email,                        phone,           full_name,          title,   roles
    ("parent",    "parent@timbitwire.demo",     "+256772894001", "Mukisa Josephine", "Ms.",   ["parent"]),
    ("teacher",   "teacher@timbitwire.demo",    "+256701000041", "Ssekandi Brian",   "Mr.",   ["teacher", "parent"]),
    ("bursar",    "bursar@timbitwire.demo",     "+256701000002", "Nsubuga Joseph",   None,    ["bursar"]),
    ("nurse",     "nurse@timbitwire.demo",      "+256701000003", "Alice Namusoke",   "Nurse", ["nurse"]),
    ("dos",       "dos@timbitwire.demo",        "+256701000004", "Ochieng Lawrence", "Mr.",   ["dos"]),
    ("cook",      "cook@timbitwire.demo",       "+256701000005", "Nakku Margaret",   "Ms.",   ["cook"]),
    ("registrar", "registrar@timbitwire.demo",  "+256701000006", "Apio Christine",   "Ms.",   ["registrar"]),
    ("director",  "director@timbitwire.demo",   "+256701000007", "Kato Robert",      "Dr.",   ["director", "admin"]),
    # extra guardians (no dashboard demo chip; exist so RLS/FKs are real)
    ("g1", "g.akello@timbitwire.demo",     "+256703552118", "Akello Sarah",       "Ms.", ["parent"]),
    ("g2", "g.byaruhanga@timbitwire.demo", "+256772041883", "Byaruhanga Edward",  "Mr.", ["parent"]),
    ("g3", "g.kembabazi@timbitwire.demo",  "+256774003902", "Kembabazi Peter",    "Mr.", ["parent"]),
    ("g4", "g.namuli@timbitwire.demo",     "+256776118040", "Namuli Stella",      "Ms.", ["parent"]),
    ("g5", "g.lamunu@timbitwire.demo",     "+256772500123", "Lamunu Okello",      "Mr.", ["parent"]),
    ("g6", "g.ssenoga@timbitwire.demo",    "+256701234567", "Ssenoga Emmanuel",   "Mr.", ["parent"]),
    ("g7", "g.ssekabira@timbitwire.demo",  "+256702812660", "Ssekabira David",    "Mr.", ["parent"]),
    ("g8", "g.okello@timbitwire.demo",     "+256703552119", "Okello Patrick",     "Mr.", ["parent"]),
    # extra staff
    ("t20", "kabuye@timbitwire.demo",     "+256701000020", "Kabuye Rose",       "Ms.", ["teacher"]),
    ("t21", "nabbosa@timbitwire.demo",    "+256701000021", "Nabbosa Joan",      "Ms.", ["teacher"]),
    ("t22", "nakato.f@timbitwire.demo",   "+256701000022", "Nakato Florence",   "Ms.", ["staff"]),
    ("t23", "walusansa@timbitwire.demo",  "+256701000023", "Walusansa Paul",    "Mr.", ["staff"]),
    ("t24", "kato.d@timbitwire.demo",     "+256701000024", "Kato Daniel",       "Mr.", ["teacher"]),
]


def req(method, path, body=None):
    r = urllib.request.Request(f"{URL}{path}", method=method, headers=HDR, data=json.dumps(body).encode() if body else None)
    try:
        with urllib.request.urlopen(r, timeout=30) as resp:
            return json.loads(resp.read() or b"{}")
    except urllib.error.HTTPError as e:
        return {"error": e.code, "body": e.read().decode()}


def find_by_email(email):
    page = 1
    while True:
        res = req("GET", f"/auth/v1/admin/users?page={page}&per_page=200")
        users = res.get("users", [])
        for u in users:
            if u.get("email") == email:
                return u
        if len(users) < 200:
            return None
        page += 1


def main():
    out = {}
    for key, email, phone, name, title, roles in USERS:
        u = find_by_email(email)
        if not u:
            u = req("POST", "/auth/v1/admin/users", {
                "email": email, "password": DEMO_PASSWORD, "email_confirm": True,
                "phone": phone, "phone_confirm": True,
                "user_metadata": {"full_name": name, "title": title, "roles": roles},
            })
            if "error" in u:
                sys.exit(f"{key}: {u}")
            print(f"created  {key:10s} {email}  {u['id']}")
        else:
            print(f"exists   {key:10s} {email}  {u['id']}")
        out[key] = {"id": u["id"], "email": email, "phone": phone, "full_name": name, "title": title, "roles": roles}
    Path("/tmp/demo_users.json").write_text(json.dumps(out, indent=2))
    print(f"\npassword for all demo users: {DEMO_PASSWORD}")
    print("ids written to /tmp/demo_users.json")


if __name__ == "__main__":
    main()
