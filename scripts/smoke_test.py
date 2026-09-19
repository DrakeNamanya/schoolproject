#!/usr/bin/env python3
"""End-to-end RLS smoke test using ONLY the public anon key (what the app ships with).
Signs in as each demo user and checks they see exactly what their role allows."""
import json
import os
import urllib.error
import urllib.request
from pathlib import Path

ENV = Path(os.environ.get("SUPABASE_ENV_FILE", Path.home() / ".secrets" / "supabase.env"))
env = {}
for line in ENV.read_text().splitlines():
    if "=" in line and not line.strip().startswith("#"):
        k, v = line.split("=", 1)
        env[k.strip()] = v.strip().strip("'\"")
URL, ANON = env["SUPABASE_URL"], env["SUPABASE_ANON_KEY"]
PW = "Timbitwire2026!"


def call(path, token, method="GET", body=None):
    h = {"apikey": ANON, "Authorization": f"Bearer {token}", "Content-Type": "application/json", "Prefer": "return=representation"}
    r = urllib.request.Request(f"{URL}{path}", method=method, headers=h, data=json.dumps(body).encode() if body else None)
    try:
        with urllib.request.urlopen(r, timeout=20) as resp:
            return resp.status, json.loads(resp.read() or b"null")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:160]


def login(email):
    s, b = call("/auth/v1/token?grant_type=password", ANON, "POST", {"email": email, "password": PW})
    assert s == 200, (email, b)
    return b["access_token"]


def count(path, tok):
    s, b = call(path, tok)
    return len(b) if isinstance(b, list) else f"ERR {s} {b}"


def main():
    ok = True

    def check(label, got, exp):
        nonlocal ok
        good = got == exp if not callable(exp) else exp(got)
        ok &= bool(good)
        print(f"  {'✓' if good else '✗'} {label}: {got}")

    print("PARENT (Mukisa Josephine)")
    t = login("parent@timbitwire.demo")
    s, me = call("/rest/v1/v_me?select=full_name,roles", t)
    check("v_me roles", me[0]["roles"] if me else None, ["parent"])
    check("children via student_guardians", count("/rest/v1/student_guardians?select=students(admission_no)", t), 2)
    check("students visible (RLS)", count("/rest/v1/students?select=id", t), 2)
    check("payments visible", count("/rest/v1/payments?select=id", t), 3)
    check("published report cards only", count("/rest/v1/report_cards?select=id", t), 1)
    check("clinic visits (own children)", count("/rest/v1/clinic_visits?select=id", t), 2)
    check("notices", count("/rest/v1/notices?select=id", t), 3)
    check("cannot see marks", count("/rest/v1/marks?select=*", t), 0)
    check("cannot see staff_alerts", count("/rest/v1/staff_alerts?select=id", t), 0)
    s, b = call("/rest/v1/payments", t, "POST", {"student_id": "20000000-0000-0000-0000-000000000478", "term_id": "10000000-0000-0000-0000-000000000002", "receipt_no": "HACK", "amount": 1, "method": "cash"})
    check("cannot post a payment", s, lambda v: v in (401, 403))

    print("TEACHER (Ssekandi Brian)")
    t = login("teacher@timbitwire.demo")
    s, me = call("/rest/v1/v_me?select=roles", t)
    check("v_me roles", sorted(me[0]["roles"]), ["parent", "teacher"])
    check("teaching_assignments (own)", count("/rest/v1/teaching_assignments?select=id", t), 4)
    check("timetable slots (own, week)", count("/rest/v1/timetable_slots?select=id", t), 35)
    check("today's attendance events (own)", count("/rest/v1/staff_attendance_events?select=id", t), lambda v: v >= 1)
    check("marks visible", count("/rest/v1/marks?select=*", t), 4)
    s, b = call("/rest/v1/marks", t, "POST", {"assessment_id": "30000000-0000-0000-0000-000000000102", "student_id": "20000000-0000-0000-0000-000000000478", "score": 30})
    check("can write marks to OPEN assessment", s, 201)
    s, b = call("/rest/v1/marks", t, "POST", {"assessment_id": "30000000-0000-0000-0000-000000000101", "student_id": "20000000-0000-0000-0000-000000000478", "score": 30})
    check("blocked on LOCKED assessment (7-day rule)", s, lambda v: v in (401, 403))
    check("staff_alerts (own)", count("/rest/v1/staff_alerts?select=id", t), lambda v: v >= 4)

    print("BURSAR (Nsubuga Joseph)")
    t = login("bursar@timbitwire.demo")
    check("all students", count("/rest/v1/students?select=id", t), 14)
    check("v_finance_kpis", count("/rest/v1/v_finance_kpis?select=*", t), 1)
    s, b = call("/rest/v1/payments", t, "POST", {"student_id": "20000000-0000-0000-0000-000000000478", "term_id": "10000000-0000-0000-0000-000000000002", "receipt_no": "R-2026-SMOKE", "amount": 50000, "method": "mtn", "reference": "smoke test"})
    check("can post payment", s, 201)
    check("cannot see clinic_visits", count("/rest/v1/clinic_visits?select=id", t), 0)

    print("PARENT again — did the bursar's payment arrive?")
    t = login("parent@timbitwire.demo")
    check("payments now", count("/rest/v1/payments?select=id", t), 4)
    check("notices now (trigger)", count("/rest/v1/notices?select=id", t), 4)

    print("NURSE (Alice Namusoke)")
    t = login("nurse@timbitwire.demo")
    check("clinic_visits (all)", count("/rest/v1/clinic_visits?select=id", t), 5)
    check("medicine_stock", count("/rest/v1/medicine_stock?select=id", t), 6)
    check("cannot see payments", count("/rest/v1/payments?select=id", t), 0)

    print("DIRECTOR (Kato Robert)")
    t = login("director@timbitwire.demo")
    check("audit_log readable", count("/rest/v1/audit_log?select=id", t), lambda v: v >= 39)
    check("v_staff_presence", count("/rest/v1/v_staff_presence?select=*", t), 12)

    # cleanup smoke rows (service role via db.py would also work)
    print("\nALL CHECKS PASSED" if ok else "\nSOME CHECKS FAILED")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
