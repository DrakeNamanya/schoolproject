# Timbitwire Girls School — Management System

One Flutter codebase, three role-based shells, built by **Data Collectors Ltd**.

| Shell | Users | Status |
|---|---|---|
| **Parent** | Guardians | ✅ Phase 1 — Home · Fees · Academics · Clinic · More |
| **Staff** | Teachers, non-teaching staff | ⏳ Phase 2 — GPS check-in, marks entry, roll call, schedule, timesheet, alerts |
| **Admin** | Director, Bursar, DOS, Nurse, Cook, Registrar, IT | ⏳ Phase 3 — 12 modules, sidebar per sub-role |

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
    placeholder_shell.dart   (staff / admin — next phases)
  widgets/     brand widgets (flag strip, crest, section title, pips, cards)
supabase/
  migrations/0001_init.sql  tables, views, triggers, RLS policies
  seed/0001_demo_data.sql   demo data (Nakato Aisha etc.)
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

## Business rules encoded so far

- Marks lock 7 days after `assessments.assessed_on` (RLS on `marks`; DOS may override)
- Parents see report cards **only** when `status = 'published'`
- Clinic visits readable by guardian, class teacher, nurse, director only
- Fee status: cleared / partial / arrears (arrears once `terms.fees_due_on` passes)
- Every payment, clinic visit and report publication fans out a `notices` row to the guardians via trigger

## Web preview build

```bash
flutter build web --release
python3 -m http.server 5060 --directory build/web --bind 0.0.0.0
```
