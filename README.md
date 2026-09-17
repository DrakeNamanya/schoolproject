# Timbitwire Girls School — Management System

One Flutter codebase, three role-based shells, built by **Data Collectors Ltd**.

| Shell | Users | Status |
|---|---|---|
| **Parent** | Guardians | ✅ Phase 1 — Home · Fees · Academics · Clinic · More |
| **Staff** | Teachers, non-teaching staff | ✅ Phase 2 — GPS geofence check-in · Schedule · Classes (marks entry with 7-day lock, roll call) · Timesheet · Alerts |
| **Admin** | Director, Bursar, DOS, Nurse, Cook, Registrar, IT | ✅ Phase 3 — **web console**, 12 modules, sidebar scoped per sub-role, writes flow to parent app |

**Core principle:** the Parent shell is read-only. Every number a parent sees was written by another role
(Bursar → fees, Teacher/DOS → marks, Nurse → clinic, Cook → menu, Registrar → students/events).

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
  seed/0001_demo_data.sql   demo data (Nakato Aisha etc.)
docs/DATA_MODEL.md          every table, PK/FK, relations, write ownership
design_reference/           original HTML/CSS clickable prototype (the spec)
```

## Running

**Demo mode (no backend)** — default. Uses seeded in-memory data and demo accounts.

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
