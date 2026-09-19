#!/usr/bin/env python3
"""Create a parent login for every student: student number + PIN.

  email    = <slug of student number>@students.timbitwire.demo   (internal)
  password = PIN (default 1234 for seeded demo students; invites carry their own)

Also processes pending guardian_invites raised by the registrar in the console.
Uses SERVICE ROLE — run server-side / by IT only. Idempotent.
"""
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from db import connect, load_env  # noqa: E402

env = load_env()
URL, KEY = env["SUPABASE_URL"], env["SUPABASE_SERVICE_ROLE_KEY"]
HDR = {"apikey": KEY, "Authorization": f"Bearer {KEY}", "Content-Type": "application/json"}
DOMAIN = "students.timbitwire.demo"
DEFAULT_PIN = "123456"  # Supabase minimum is 6 chars


def req(method, path, body=None):
    r = urllib.request.Request(f"{URL}{path}", method=method, headers=HDR, data=json.dumps(body).encode() if body else None)
    try:
        with urllib.request.urlopen(r, timeout=30) as resp:
            return json.loads(resp.read() or b"{}")
    except urllib.error.HTTPError as e:
        return {"error": e.code, "body": e.read().decode()}


def all_auth_users():
    out, page = {}, 1
    while True:
        res = req("GET", f"/auth/v1/admin/users?page={page}&per_page=200")
        users = res.get("users", [])
        for u in users:
            if u.get("email"):
                out[u["email"].lower()] = u
        if len(users) < 200:
            return out
        page += 1


def slug(no):
    import re
    return re.sub(r"[^A-Za-z0-9]+", "-", no.strip()).lower()


def main():
    conn = connect(env)
    cur = conn.cursor()
    users = all_auth_users()

    # 1. every active student gets a login ---------------------------------
    cur.execute("select s.id, s.admission_no, s.surname || ' ' || s.first_name, l.auth_user_id from students s left join student_logins l on l.student_id = s.id where s.active order by s.admission_no")
    created = linked = 0
    for sid, no, name, existing in cur.fetchall():
        email = f"{slug(no)}@{DOMAIN}"
        u = users.get(email)
        if not u:
            u = req("POST", "/auth/v1/admin/users", {
                "email": email, "password": DEFAULT_PIN, "email_confirm": True,
                "user_metadata": {"student_no": no, "student_name": name, "kind": "student_login"},
            })
            if "error" in u:
                print(f"  ! {no}: {u}")
                continue
            users[email] = u
            created += 1
        auth_id = u["id"]
        # profile + parent role + guardian link + student_logins row
        cur.execute("insert into profiles (id, full_name, email) values (%s,%s,%s) on conflict (id) do nothing", (auth_id, f"Guardian of {name}", email))
        cur.execute("insert into user_roles values (%s,'parent') on conflict do nothing", (auth_id,))
        cur.execute("insert into student_guardians (student_id, guardian_id, relationship, is_primary) values (%s,%s,'student-login',false) on conflict do nothing", (sid, auth_id))
        cur.execute("""insert into student_logins (student_id, login_email, auth_user_id, pin_set_at) values (%s,%s,%s,now())
                       on conflict (student_id) do update set login_email = excluded.login_email, auth_user_id = excluded.auth_user_id""", (sid, email, auth_id))
        if existing is None:
            linked += 1
    # a student-login account also sees siblings that share a real guardian
    cur.execute("""
      insert into student_guardians (student_id, guardian_id, relationship, is_primary)
      select distinct sg2.student_id, l.auth_user_id, 'sibling-login', false
      from student_logins l
      join student_guardians sg1 on sg1.student_id = l.student_id and sg1.relationship <> 'student-login'
      join student_guardians sg2 on sg2.guardian_id = sg1.guardian_id and sg2.relationship <> 'student-login'
      where sg2.student_id <> l.student_id
      on conflict do nothing""")
    conn.commit()
    print(f"student logins: {created} auth users created, {linked} linked (PIN {DEFAULT_PIN} for new ones)")

    # 2. process pending guardian invites (registrar enrolments) ------------------
    cur.execute("select i.id, i.student_id, i.guardian_name, i.guardian_phone, i.relationship, i.pin, s.admission_no from guardian_invites i join students s on s.id = i.student_id where i.processed_at is null")
    invites = cur.fetchall()
    for iid, sid, gname, gphone, rel, pin, no in invites:
        try:
            email = f"{slug(no)}@{DOMAIN}"
            u = users.get(email)
            if u and pin:
                req("PUT", f"/auth/v1/admin/users/{u['id']}", {"password": pin})
            # guardian's own profile by phone (so SMS + name are right)
            cur.execute("select id from profiles where regexp_replace(phone,'\\D','','g') = regexp_replace(%s,'\\D','','g') limit 1", (gphone,))
            row = cur.fetchone()
            if row:
                cur.execute("insert into student_guardians (student_id, guardian_id, relationship, is_primary) values (%s,%s,%s,true) on conflict do nothing", (sid, row[0], rel))
            elif u:
                cur.execute("update profiles set full_name = %s, phone = %s where id = %s and full_name like 'Guardian of%%'", (gname, gphone, u["id"]))
            cur.execute("update guardian_invites set processed_at = now(), pin = null where id = %s", (iid,))
            print(f"  invite {no}: guardian {gname} linked, PIN set")
        except Exception as e:  # noqa: BLE001
            cur.execute("update guardian_invites set error = %s where id = %s", (str(e)[:200], iid))
            print(f"  invite {no} FAILED: {e}")
    conn.commit()
    print(f"invites processed: {len(invites)}")
    conn.close()


if __name__ == "__main__":
    main()
