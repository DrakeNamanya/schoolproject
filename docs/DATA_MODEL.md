# Timbitwire School — Data Model

Database: **Supabase (PostgreSQL)**. Auth: Supabase Auth (`auth.users`). Push: Firebase Cloud Messaging (tokens stored here, no data in Firebase).

All primary keys are `uuid` (`gen_random_uuid()`) unless stated. All timestamps are `timestamptz` in EAT (+03:00). Money is `bigint` in whole Ugandan shillings.

- `0001_init.sql` — Phase 1 (identity, students, fees, academics, clinic, kitchen, events, notices)
- `0002_staff.sql` — Phase 2 (classes, subjects, staff, timetable, geofence, attendance events, timesheets, staff alerts, audit)
- `0003_admin.sql` — Phase 3 (requisitions, purchase orders, stock items, issue vouchers, medicine stock, KPI views)

---

## 1. Entity-relationship overview

```
                                   auth.users
                                       │ 1:1
                                   ┌───┴────┐
                                   │profiles│──────────────┐
                                   └───┬────┘              │ 1:N
              ┌────────────────────────┼──────────┐   ┌────┴─────┐
              │ 1:N                    │ 1:1      │   │user_roles│
        ┌─────┴──────────┐      ┌──────┴───────┐  │   └──────────┘
        │student_guardians│      │staff_profiles│  │ 1:N
        └─────┬──────────┘      └──────┬───────┘  │
              │ N:1                    │          │
        ┌─────┴────┐   N:1  ┌──────┐   │ 1:N   ┌──┴──────────┐
        │ students │────────│classes│◄──┼───────│teaching_    │
        └─────┬────┘        └──┬───┘   │       │assignments  │──N:1──┐
              │                │       │       └─────────────┘       │
              │                │ 1:N   │                       ┌─────┴───┐
              │           ┌────┴────────┐                      │subjects │
              │           │timetable_   │──N:1─────────────────┴─────────┘
              │           │slots        │
              │           └─────────────┘
              │
   ┌──────────┼──────────────┬──────────────┬──────────────┬─────────────┐
   │ 1:N      │ 1:N          │ 1:N          │ 1:N          │ 1:N         │ 1:N
┌──┴──────┐ ┌─┴───────┐ ┌────┴──────┐ ┌─────┴──────┐ ┌─────┴───────┐ ┌───┴──────┐
│fee_lines│ │payments │ │attendance │ │clinic_visits│ │report_cards │ │  marks   │
└──┬──────┘ └─┬───────┘ └─────┬─────┘ └────────────┘ └──────┬──────┘ └───┬──────┘
   │ N:1      │ N:1           │ N:1                          │ 1:N         │ N:1
   └──────────┴───────────────┴──────► terms ◄───────────────┤       ┌─────┴───────┐
                                                             │       │ assessments │──N:1──► classes, subjects, terms
                                                   ┌─────────┴────────┐└─────────────┘
                                                   │report_card_results│
                                                   └──────────────────┘

staff_profiles ──1:N──► staff_attendance_events ──N:1──► geofences
staff_profiles ──1:N──► timesheets ──N:1──► terms
profiles       ──1:N──► notices, staff_alerts, device_tokens, audit_log
```

---

## 2. Identity & roles

### `profiles`
One row per person who can sign in (parent, teacher, bursar…).

| Column | Type | Key | Notes |
|---|---|---|---|
| `id` | uuid | **PK**, FK → `auth.users.id` | Same id as the Supabase auth user |
| `full_name` | text | | |
| `title` | text | | Ms., Mr., Nurse, Dr. |
| `phone` | text | UNIQUE | E.164, e.g. +256772894001 — used for SMS + login |
| `email` | text | | |
| `created_at` | timestamptz | | |

### `user_roles`
A person may hold several roles (teacher who is also a parent).

| Column | Type | Key |
|---|---|---|
| `user_id` | uuid | **PK(1)**, FK → `profiles.id` |
| `role` | `app_role` enum | **PK(2)** |

`app_role` = `parent · teacher · staff · director · bursar · dos · nurse · cook · registrar · admin`

### `staff_profiles` *(0002)*
Employment record for anyone with a staff-type role.

| Column | Type | Key | Notes |
|---|---|---|---|
| `user_id` | uuid | **PK**, FK → `profiles.id` | |
| `staff_no` | text | UNIQUE | STAFF/2021/041 |
| `department` | text | | Physics, Kitchen, Clinic |
| `job_title` | text | | Teacher, Head cook |
| `duty_start` | time | | 07:30 |
| `duty_end` | time | | 17:00 |
| `weekly_target_minutes` | int | | 2400 (= 40 h) |
| `auto_checkin` | boolean | | staff may turn GPS auto check-in off |
| `active` | boolean | | |

---

## 3. Academic structure

### `terms`
| Column | Type | Key | Notes |
|---|---|---|---|
| `id` | uuid | **PK** | |
| `year`, `number` | int | UNIQUE(year, number) | number ∈ 1..3 |
| `starts_on`, `ends_on` | date | | |
| `fees_due_on` | date | | drives arrears status |
| `is_current` | boolean | | exactly one true |

### `classes` *(0002)*
| Column | Type | Key | Notes |
|---|---|---|---|
| `id` | uuid | **PK** | |
| `name` | text | UNIQUE | S2 East |
| `level` | int | | 1..6 |
| `stream` | text | | East |
| `class_teacher_id` | uuid | FK → `profiles.id` | writes attendance + class comment |
| `capacity` | int | | |

### `subjects` *(0002)*
| Column | Type | Key | Notes |
|---|---|---|---|
| `id` | uuid | **PK** | |
| `code` | text | UNIQUE | PHY |
| `name` | text | | Physics |

### `teaching_assignments` *(0002)*
Which teacher teaches which subject to which class this term. Drives the "Classes" tab in the staff app and the marks-write RLS.

| Column | Type | Key |
|---|---|---|
| `id` | uuid | **PK** |
| `teacher_id` | uuid | FK → `profiles.id` |
| `class_id` | uuid | FK → `classes.id` |
| `subject_id` | uuid | FK → `subjects.id` |
| `term_id` | uuid | FK → `terms.id` |
| | | UNIQUE(teacher_id, class_id, subject_id, term_id) |

### `timetable_slots` *(0002)*
| Column | Type | Key | Notes |
|---|---|---|---|
| `id` | uuid | **PK** | |
| `term_id` | uuid | FK → `terms.id` | |
| `weekday` | int | | 1=Mon … 7=Sun |
| `starts_at`, `ends_at` | time | | |
| `teacher_id` | uuid | FK → `profiles.id` | |
| `class_id` | uuid | FK → `classes.id`, nullable | null for duties (break duty, prep) |
| `subject_id` | uuid | FK → `subjects.id`, nullable | |
| `title` | text | | used when class/subject null |
| `room` | text | | Lab 2 |

---

## 4. Students

### `students`
| Column | Type | Key | Notes |
|---|---|---|---|
| `id` | uuid | **PK** | |
| `admission_no` | text | UNIQUE | TGS/2024/00478 |
| `first_name`, `surname` | text | | |
| `class_id` | uuid | FK → `classes.id` *(0002 adds; 0001 had `class_name` text)* | |
| `class_name` | text | | denormalised for display |
| `house` | text | | Green / Blue / Red / White |
| `is_boarder` | boolean | | |
| `dormitory` | text | | Kwagala dormitory, bed 14 |
| `date_of_birth`, `admitted_on` | date | | |
| `photo_url` | text | | |
| `active` | boolean | | |

### `student_guardians`
| Column | Type | Key | Notes |
|---|---|---|---|
| `student_id` | uuid | **PK(1)**, FK → `students.id` | |
| `guardian_id` | uuid | **PK(2)**, FK → `profiles.id` | |
| `relationship` | text | | mother / father / guardian |
| `is_primary` | boolean | | receives SMS |

> **This join table is the security boundary for the whole Parent app.** `is_guardian_of(student_id)` is evaluated in every parent-facing RLS policy.

---

## 5. Finance (written by **Bursar**)

### `fee_lines`
| Column | Type | Key |
|---|---|---|
| `id` | uuid | **PK** |
| `student_id` | uuid | FK → `students.id` |
| `term_id` | uuid | FK → `terms.id` |
| `label` | text | Tuition / Boarding / Lunch programme / Uniforms |
| `amount` | bigint ≥ 0 | |
| `created_by` | uuid | FK → `profiles.id` |

### `payments`
| Column | Type | Key | Notes |
|---|---|---|---|
| `id` | uuid | **PK** | |
| `student_id` | uuid | FK → `students.id` | |
| `term_id` | uuid | FK → `terms.id` | |
| `receipt_no` | text | UNIQUE | R-2026-0891 |
| `amount` | bigint > 0 | | |
| `method` | `payment_method` enum | | mtn · airtel · bank · cash · other |
| `reference` | text | | MM transaction id / bank slip |
| `paid_at` | timestamptz | | |
| `posted_by` | uuid | FK → `profiles.id`, nullable | null = payment gateway |

Balance = Σ`fee_lines.amount` − Σ`payments.amount` per (student, term). Computed in app / view, never stored.

### `payment_channels`
School-wide instructions (MTN code, bank account). PK `id`; no FKs.

---

## 6. Academics (written by **Teachers**, compiled/published by **DOS**)

### `assessments`
| Column | Type | Key | Notes |
|---|---|---|---|
| `id` | uuid | **PK** | |
| `term_id` | uuid | FK → `terms.id` | |
| `class_id` | uuid | FK → `classes.id` | |
| `subject_id` | uuid | FK → `subjects.id` | |
| `title` | text | | CAT 1, CAT 2, Assignment, Mid-term |
| `out_of` | int | | 40 |
| `assessed_on` | date | | |
| `locks_at` | timestamptz | generated | `assessed_on + 7 days` — **7-day lock** |
| `teacher_id` | uuid | FK → `profiles.id` | |

### `marks`
| Column | Type | Key |
|---|---|---|
| `assessment_id` | uuid | **PK(1)**, FK → `assessments.id` |
| `student_id` | uuid | **PK(2)**, FK → `students.id` |
| `score` | int | |
| `comment` | text | |
| `entered_by` | uuid | FK → `profiles.id` |
| `updated_at` | timestamptz | |

RLS: teacher may write only while `now() < assessments.locks_at` **and** holds a `teaching_assignments` row for that class+subject; DOS/admin may override.

### `report_cards`
| Column | Type | Key | Notes |
|---|---|---|---|
| `id` | uuid | **PK** | |
| `student_id` | uuid | FK → `students.id` | UNIQUE(student_id, term_id) |
| `term_id` | uuid | FK → `terms.id` | |
| `position`, `class_size` | int | | |
| `class_teacher_comment`, `headteacher_comment` | text | | |
| `status` | `report_status` enum | | draft → review → **published** |
| `published_at` | timestamptz | | |
| `published_by` | uuid | FK → `profiles.id` | |
| `pdf_url` | text | | Supabase Storage |

### `report_card_results`
| Column | Type | Key |
|---|---|---|
| `id` | uuid | **PK** |
| `report_card_id` | uuid | FK → `report_cards.id` |
| `subject` | text | |
| `cat_score`, `cat_out_of`, `exam_score`, `exam_out_of` | int | |
| `grade` | text | D1 … F9 |
| `teacher_comment` | text | |

### `attendance` (learners — written by **class teacher**)
| Column | Type | Key |
|---|---|---|
| `id` | uuid | **PK** |
| `student_id` | uuid | FK → `students.id`, UNIQUE(student_id, on_date) |
| `term_id` | uuid | FK → `terms.id` |
| `on_date` | date | |
| `present` | boolean | |
| `marked_by` | uuid | FK → `profiles.id` |

---

## 7. Clinic (written by **Nurse**)

### `clinic_visits`
| Column | Type | Key | Notes |
|---|---|---|---|
| `id` | uuid | **PK** | |
| `student_id` | uuid | FK → `students.id` | |
| `visited_at` | timestamptz | | |
| `complaint`, `notes`, `treatment` | text | | |
| `vitals` | jsonb | | `[{"label":"Temp","value":"37.9°C"}]` |
| `outcome` | `visit_outcome` enum | | discharged · observing · followUp · referred |
| `follow_up_note`, `referral_facility` | text | | |
| `recorded_by` | uuid | FK → `profiles.id` | |
| `recorded_by_name` | text | | denormalised for display |

---

## 8. Kitchen, events, documents

### `menus` (written by **Cook**) — PK `menu_date` (date). Columns: breakfast/lunch/supper + `_side`, `published_by` FK → profiles.
### `events` (written by **Director/Registrar**) — PK `id`; `category` enum academic · coCurricular · community; `highlight` bool.
### `documents` — PK `id`; `student_id` FK → students **nullable** (null = school-wide).

---

## 9. Staff attendance & GPS *(0002, written by **system** from the staff app)*

### `geofences`
| Column | Type | Key | Notes |
|---|---|---|---|
| `id` | uuid | **PK** | |
| `name` | text | | Main campus |
| `lat`, `lng` | double | | centre |
| `radius_m` | int | | 120 |
| `grace_minutes` | int | | 15 |
| `active` | boolean | | |

### `staff_attendance_events`
Raw event log. One row per entry/exit. Immutable.

| Column | Type | Key | Notes |
|---|---|---|---|
| `id` | uuid | **PK** | |
| `staff_id` | uuid | FK → `staff_profiles.user_id` | |
| `geofence_id` | uuid | FK → `geofences.id` | |
| `kind` | `attendance_kind` enum | | auto_in · auto_out · manual_in · manual_out · flagged_off_campus |
| `at` | timestamptz | | |
| `lat`, `lng` | double | | |
| `accuracy_m` | double | | ±6 m |
| `distance_m` | double | | from fence centre |
| `in_duty_window` | boolean | | GPS only sampled inside duty window (Data Protection Act 2019) |

### `timesheets`
Derived daily summary (one row per staff per day), recomputed by trigger from events.

| Column | Type | Key |
|---|---|---|
| `staff_id` | uuid | **PK(1)**, FK → `staff_profiles.user_id` |
| `on_date` | date | **PK(2)** |
| `term_id` | uuid | FK → `terms.id` |
| `first_in`, `last_out` | timestamptz | |
| `minutes_worked` | int | |
| `late_minutes` | int | beyond grace |
| `status` | text | full_day · partial · absent · in_progress |
| `approved_by` | uuid | FK → `profiles.id` — locked once payroll approves |

### `staff_alerts`
| Column | Type | Key | Notes |
|---|---|---|---|
| `id` | uuid | **PK** | |
| `recipient_id` | uuid | FK → `profiles.id` | |
| `severity` | text | | danger · warn · success · info |
| `source` | text | | Geofence · Academics · Procurement · System |
| `title`, `body` | text | | |
| `related_staff_id` | uuid | FK → `profiles.id`, nullable | e.g. the flagged teacher |
| `read` | boolean | | |
| `created_at` | timestamptz | | |

---

## 10. Cross-cutting

### `notices` — parent inbox. PK `id`; `recipient_id` FK → profiles; `student_id` FK → students (nullable). Populated **only by triggers** on `payments`, `clinic_visits`, `report_cards`.
### `device_tokens` — PK(user_id, token); `user_id` FK → profiles. FCM tokens.
### `audit_log` *(0002)* — PK `id`; `actor_id` FK → profiles; `action`, `entity`, `entity_id`, `before`/`after` jsonb, `severity`. Append-only; triggers on payments, marks, clinic_visits, report_cards, staff_attendance_events.

---

## 11. Procurement *(0003, written by any staff; status changed by **Bursar → Director**)*

### `requisitions`
| Column | Type | Key | Notes |
|---|---|---|---|
| `id` | uuid | **PK** | |
| `ref` | text | UNIQUE | REQ-0347 |
| `title`, `department` | text | | |
| `requester_id` | uuid | FK → `profiles.id` | |
| `amount` | bigint | | Σ lines |
| `status` | `requisition_status` enum | | bursar → director → approved → poRaised → delivered · rejected |
| `bursar_by`, `director_by` | uuid | FK → `profiles.id` | sign-off trail |

### `requisition_lines` — PK `id`; FK `requisition_id` → requisitions (cascade); qty, unit, unit_price.
### `purchase_orders` — PK `id`; `po_no` UNIQUE; FK `requisition_id` → requisitions **UNIQUE** (one PO per approved requisition); supplier, amount, `raised_by` FK → profiles.

## 12. Stores *(0003, written by **Bursar** / stores officer)*

### `stock_items` — PK `id`; `sku` UNIQUE; category, unit, `on_hand`, `reorder_at`. Reorder alert when `on_hand < reorder_at`.
### `issue_vouchers` — PK `id`; `voucher_no` UNIQUE; FK `stock_item_id` → stock_items; qty, issued_to, `issued_by` FK → profiles. **Trigger decrements `stock_items.on_hand`.**

## 13. Clinic stock *(0003, written by **Nurse**)*

### `medicine_stock` — PK `id`; name, batch, expires_on, qty, unit, reorder_at.
### `medicine_issues` — PK `id`; FK `medicine_id` → medicine_stock; FK `clinic_visit_id` → clinic_visits (set null); qty. **Trigger decrements `medicine_stock.qty`.**

## 14. Views used by the admin console

| View | Feeds | Source tables |
|---|---|---|
| `v_me` | login → roles | profiles, user_roles |
| `v_student_summary` | parent hero card, student profile | attendance, report_cards, clinic_visits |
| `v_finance_kpis` | Dashboard, Finance KPIs | fee_lines, payments, terms, students |
| `v_student_fees` | Finance arrears table, Students roster | fee_lines, payments |
| `v_staff_presence` | Attendance & GPS module, Dashboard "staff on-campus" | staff_profiles, staff_attendance_events |

## 15. Admin console — module → sub-role → tables

| Module | Roles | Reads | Writes |
|---|---|---|---|
| Dashboard | director, admin, bursar, dos | v_finance_kpis, v_staff_presence, events, staff_alerts, requisitions | – |
| Finance | bursar, director | v_finance_kpis, v_student_fees, payments | **payments**, fee_lines |
| Students | registrar, director, dos, bursar | students, student_guardians, v_student_summary, v_student_fees | **students, student_guardians, profiles** |
| Academics | dos, director | report_cards, report_card_results, assessments, marks | **report_cards.status → published** |
| Attendance & GPS | dos, director, bursar | v_staff_presence, staff_attendance_events, geofences | geofences |
| Clinic | nurse, director | clinic_visits, medicine_stock | **clinic_visits**, medicine_issues |
| Kitchen | cook, director, bursar | menus, stock_items (Kitchen) | **menus**, requisitions |
| Events | registrar, director | events | **events** |
| Procurement | bursar, director, dos | requisitions, purchase_orders | requisitions.status, purchase_orders |
| Stores | bursar, director | stock_items, issue_vouchers | issue_vouchers |
| Reports | director, dos, bursar | all read views | – |
| Audit log | director, admin | audit_log | – |

---

## 16. Write ownership → what the parent sees

| Parent screen element | Table(s) read | Written by | Trigger → `notices`? |
|---|---|---|---|
| Hero: name, class, house, dorm | `students` | Registrar | – |
| Hero: attendance % | `attendance` via `v_student_summary` | Class teacher (roll call) | – |
| Hero: position | `report_cards` | DOS | – |
| Hero: clinic count | `clinic_visits` | Nurse | – |
| Balance, statement lines | `fee_lines` | Bursar | – |
| Receipts | `payments` | Bursar / gateway | ✅ payment |
| Pay-now channels | `payment_channels` | Bursar | – |
| Report card | `report_cards` + `report_card_results` (status = published) | Teachers → DOS | ✅ academics |
| Clinic visits | `clinic_visits` | Nurse | ✅ clinic |
| Today's menu | `menus` | Cook | – |
| Events | `events` | Director / Registrar | (phase 3: 48 h reminder) |
| Documents | `documents` | Registrar / Bursar | – |
| Notification bell | `notices` | System | – |

## 17. Staff shell data flow

| Staff screen | Reads | Writes |
|---|---|---|
| Check-in | `geofences`, `staff_profiles`, today's `staff_attendance_events` | `staff_attendance_events` (auto/manual) |
| Schedule | `timetable_slots` (own, this week) | – |
| Classes → Marks | `teaching_assignments`, `assessments`, `marks`, `students` | `assessments`, `marks` (until lock) |
| Classes → Roll call | class roster from `students` | `attendance` (class teacher only) |
| Timesheet | `timesheets` (own) | – |
| Alerts | `staff_alerts` (own) | `read` flag |
