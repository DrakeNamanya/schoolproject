# Timbitwire Girls School — Management System

One Flutter codebase, three role-based shells, built by **Data Collectors Ltd**.

| Shell | Users | Status |
|---|---|---|
| **Parent** | Guardians | ✅ Phase 1 — Home · Fees · Academics · Clinic · More |
| **Staff** | Teachers, non-teaching staff | ✅ Phase 2 — GPS geofence check-in · Schedule · Classes (marks entry with 7-day lock, roll call) · Timesheet · Alerts |
| **Admin** | Director, Bursar, DOS, Nurse, Cook, Registrar, IT | ✅ Phase 3 — **web console**, 12 modules, sidebar scoped per sub-role, writes flow to parent app |

**Core principle:** the Parent shell is read-only. Every number a parent sees was written by another role
(Bursar → fees, Teacher/DOS → marks, Nurse → clinic, Cook → menu, Registrar → students/events).

## The student number is the key

`students.admission_no` (e.g. **TGS/2024/00478**) is the one identifier everybody uses:

| Who | What they type the student number for |
|---|---|
| **Parent** | **Logs in** with student number + 6-digit PIN → sees that student and her siblings |
| Bursar | Post payment (`post_payment(student_no, …)` RPC) |
| Nurse | Record clinic visit |
| Teacher | Marks grid / roll call rows show it |
| Registrar | Issued automatically on enrolment (`enrol_student` RPC → `TGS/YYYY/NNNNN`) |

Internally Postgres keeps a uuid for foreign keys; the number is `UNIQUE NOT NULL` and never changes.
Each student has an internal auth account `<slug>@students.timbitwire.demo`; `scripts/provision_student_logins.py` creates them and processes registrar enrolment invites.

## Stack

- **Flutter 3.35 / Dart 3.9**, Provider, Material 3 with the Timbitwire design tokens
  (`lib/theme/`) ported from `design_reference/timbitwire-tokens.css`
- **Supabase** — Postgres + Auth + RLS. Schema in `supabase/migrations/`, demo seed in `supabase/seed/`
- **Firebase Cloud Messaging** — push alerts **only**. No app data lives in Firebase.
- Package id: `com.timbitwireschool.management`

## Project layout

```
lib/
  core/        config, auth/session provider, push service, formatters
  theme/       tokens + ThemeData
  models/      user, student, fees, academics, clinic, school
  data/        ParentRepository interface + Supabase and in-memory mock implementations
  features/
    auth/      login, role picker
    parent/    provider, shell, 5 screens
    staff/     provider (geofence state machine), shell, 5 screens + marks entry + roll call
    admin/     web shell (sidebar, topbar), admin_modules (role → module map), 12 modules
  widgets/phone_frame.dart   phone bezel for Parent/Staff on wide web viewports
  data/mock/demo_store.dart  single in-memory store shared by all three shells
  widgets/     brand widgets (flag strip, crest, section title, pips, cards)
supabase/
  migrations/0001_init.sql  Phase 1 tables, views, triggers, RLS policies
  migrations/0002_staff.sql Phase 2: classes, subjects, staff, timetable, geofence, timesheets, alerts, audit
  migrations/0003_admin.sql Phase 3: requisitions, purchase orders, stock, issue vouchers, medicine stock, KPI views
  migrations/0004_student_number.sql  student logins, enrolment invites, post_payment/enrol_student RPCs, admin views
  seed/0001_demo_data.sql   demo data (Nakato Aisha etc.)
docs/DATA_MODEL.md          every table, PK/FK, relations, write ownership
design_reference/           original HTML/CSS clickable prototype (the spec)
```

## Running

**Live (Supabase)** — `scripts/run_web.sh`, `scripts/build_web.sh`, `scripts/build_apk.sh` read credentials from `~/.secrets/supabase.env`.

**Demo mode (no backend)** — build without `--dart-define`s. Uses seeded in-memory data and demo chips.

```bash
flutter pub get
flutter run -d chrome
```

**Against Supabase**

1. Create a Supabase project, run `supabase/migrations/0001_init.sql` in the SQL editor.
2. Auth → Users → add a parent user; paste its uuid into `supabase/seed/0001_demo_data.sql` and run it.
3. Build with credentials injected (never commit them):
   ```bash
   flutter run -d chrome \
     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=sb_publishable_...
   ```

**Push alerts (FCM)**

1. Drop `google-services.json` into `android/app/`.
2. Add `--dart-define=ENABLE_PUSH=true`.
3. Device tokens are stored in `device_tokens`; a Supabase Edge Function (phase 2) fans out
   pushes when a `notices` row is inserted.

## Form factors

- **Parent** and **Staff** are phone apps (bottom tabs, portrait). On wide web viewports they render inside a phone frame.
- **Admin** is a web app: persistent sidebar ≥ 1024 px, drawer below; modules are scoped to the signed-in sub-role
  (bursar → Finance/Procurement/Stores; nurse → Clinic; cook → Kitchen; registrar → Students/Events; dos → Academics/Attendance; director → everything).

## Demo the data flow (no backend needed)

1. Sign in as **Bursar** → Finance → *Post payment* for Nakato Aisha.
2. Sign out, sign in as **Parent** → the receipt is on Home, Fees and in the bell.
3. Sign in as **Nurse** → *Record a visit*; as **Cook** → edit today's menu; as **DOS** → publish Grace's report card; as **Registrar** → enrol a student. Each shows up in the parent app.

## Test accounts (live database)

| Role | Login | Password / PIN |
|---|---|---|
| Parent | `TGS/2024/00478` (any student number) | `123456` |
| Teacher | `teacher@timbitwire.demo` | `Timbitwire2026!` |
| Bursar · Nurse · DOS · Cook · Registrar · Director | `bursar@` `nurse@` `dos@` `cook@` `registrar@` `director@timbitwire.demo` | `Timbitwire2026!` |

## Deploy to Netlify

1. Netlify → **Add new site → Import from Git** → this repo.
2. Build settings are read from `netlify.toml` (command `bash netlify/build.sh`, publish `build/web`).
3. **Site settings → Environment variables** add `SUPABASE_URL` and `SUPABASE_ANON_KEY` (the anon JWT — never the secret/service key).
4. Deploy. First build ~6 min (clones Flutter 3.35.4); later builds are cached.
5. Supabase → Authentication → URL Configuration: add the Netlify URL to **Redirect URLs**.

## Provisioning / ops scripts

```bash
scripts/db.py supabase/migrations/000N_*.sql   # apply a migration
scripts/db.py --query "select …"               # ad-hoc SQL
scripts/seed_users.py                          # demo staff/guardian auth users
scripts/seed_data.py                           # demo rows (wipes & reseeds)
scripts/provision_student_logins.py            # student-number logins + pending enrolment invites
scripts/smoke_test.py                          # 30 RLS checks with the anon key
```

## Business rules encoded so far

- Marks lock 7 days after `assessments.assessed_on` (RLS on `marks`; DOS may override)
- Parents see report cards **only** when `status = 'published'`
- Clinic visits readable by guardian, class teacher, nurse, director only
- Fee status: cleared / partial / arrears (arrears once `terms.fees_due_on` passes)
- Every payment, clinic visit and report publication fans out a `notices` row to the guardians via trigger
- Staff GPS sampled only inside the duty window; auto check-in/out on geofence crossing; off-campus during a lesson raises a `staff_alerts` row to DOS/Director
- Timesheets recomputed from `staff_attendance_events` by trigger; locked once bursar approves

## Web preview build

```bash
flutter build web --release
python3 -m http.server 5060 --directory build/web --bind 0.0.0.0
```
