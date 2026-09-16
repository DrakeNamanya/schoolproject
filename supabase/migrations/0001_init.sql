-- ============================================================
-- Timbitwire Girls School — Supabase schema (phase 1: parent shell)
-- Run in Supabase SQL editor or via `supabase db push`.
--
-- Write ownership (enforced by RLS below):
--   profiles / user_roles      admin, registrar
--   students, student_guardians registrar
--   terms                      director, registrar
--   fee_lines, payments,
--   payment_channels           bursar
--   assessments, marks         teacher (own subject), dos
--   report_cards (+results)    dos, director (publish)
--   clinic_visits              nurse
--   menus                      cook
--   events, documents          director, registrar, bursar
--   notices                    system (triggers) — parents read own
-- ============================================================

create extension if not exists "pgcrypto";

-- ---------- Roles & profiles ----------
create type app_role as enum (
  'parent','teacher','staff','director','bursar','dos','nurse','cook','registrar','admin'
);

create table profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text not null,
  title       text,
  phone       text unique,
  email       text,
  created_at  timestamptz default now()
);

create table user_roles (
  user_id  uuid references profiles(id) on delete cascade,
  role     app_role not null,
  primary key (user_id, role)
);

-- Helper: does the current user hold any of these roles?
create or replace function has_role(variadic roles app_role[])
returns boolean language sql stable security definer as $$
  select exists (
    select 1 from user_roles
    where user_id = auth.uid() and role = any(roles)
  );
$$;

-- View used by the app on login
create or replace view v_me as
select p.*, coalesce(array_agg(r.role) filter (where r.role is not null), '{}') as roles
from profiles p
left join user_roles r on r.user_id = p.id
where p.id = auth.uid()
group by p.id;

-- ---------- Academic calendar ----------
create table terms (
  id           uuid primary key default gen_random_uuid(),
  year         int  not null,
  number       int  not null check (number between 1 and 3),
  starts_on    date not null,
  ends_on      date not null,
  fees_due_on  date,
  is_current   boolean default false,
  unique (year, number)
);

-- ---------- Students ----------
create table students (
  id            uuid primary key default gen_random_uuid(),
  admission_no  text unique not null,          -- TGS/2024/00478
  first_name    text not null,
  surname       text not null,
  class_name    text not null,                 -- S2 East
  house         text,
  is_boarder    boolean default true,
  dormitory     text,
  date_of_birth date,
  admitted_on   date,
  photo_url     text,
  active        boolean default true,
  created_at    timestamptz default now()
);

create table student_guardians (
  student_id   uuid references students(id) on delete cascade,
  guardian_id  uuid references profiles(id) on delete cascade,
  relationship text,                            -- mother, father, guardian
  is_primary   boolean default false,
  primary key (student_id, guardian_id)
);

create or replace function is_guardian_of(sid uuid)
returns boolean language sql stable security definer as $$
  select exists (
    select 1 from student_guardians
    where student_id = sid and guardian_id = auth.uid()
  );
$$;

-- ---------- Fees (Bursar) ----------
create table fee_lines (
  id          uuid primary key default gen_random_uuid(),
  student_id  uuid references students(id) on delete cascade,
  term_id     uuid references terms(id),
  label       text not null,                    -- Tuition
  amount      bigint not null check (amount >= 0),
  created_by  uuid references profiles(id),
  created_at  timestamptz default now()
);

create type payment_method as enum ('mtn','airtel','bank','cash','other');

create table payments (
  id          uuid primary key default gen_random_uuid(),
  student_id  uuid references students(id) on delete cascade,
  term_id     uuid references terms(id),
  receipt_no  text unique not null,             -- R-2026-0891
  amount      bigint not null check (amount > 0),
  method      payment_method not null,
  reference   text,
  paid_at     timestamptz not null default now(),
  posted_by   uuid references profiles(id),     -- null = gateway
  created_at  timestamptz default now()
);

create table payment_channels (
  id          uuid primary key default gen_random_uuid(),
  method      payment_method not null,
  title       text not null,
  instruction text not null,
  active      boolean default true,
  sort_order  int default 0
);

-- ---------- Academics (Teachers -> DOS -> parents) ----------
create type report_status as enum ('draft','review','published');

create table report_cards (
  id                    uuid primary key default gen_random_uuid(),
  student_id            uuid references students(id) on delete cascade,
  term_id               uuid references terms(id),
  term_label            text,
  class_name            text,
  position              int,
  class_size            int,
  class_teacher_name    text,
  class_teacher_comment text,
  headteacher_comment   text,
  status                report_status default 'draft',
  published_at          timestamptz,
  published_by          uuid references profiles(id),
  pdf_url               text,
  unique (student_id, term_id)
);

create table report_card_results (
  id              uuid primary key default gen_random_uuid(),
  report_card_id  uuid references report_cards(id) on delete cascade,
  subject         text not null,
  cat_score       int default 0,
  cat_out_of      int default 40,
  exam_score      int default 0,
  exam_out_of     int default 60,
  grade           text,
  teacher_comment text,
  sort_order      int default 0
);

-- Raw marks entry (staff app) — feeds report_card_results when DOS compiles.
create table assessments (
  id             uuid primary key default gen_random_uuid(),
  term_id        uuid references terms(id),
  class_name     text not null,
  subject        text not null,
  title          text not null,                 -- CAT 2
  out_of         int  not null,
  assessed_on    date not null,
  locks_at       timestamptz generated always as ((assessed_on + interval '7 days')::timestamptz) stored,
  teacher_id     uuid references profiles(id),
  created_at     timestamptz default now()
);

create table marks (
  assessment_id uuid references assessments(id) on delete cascade,
  student_id    uuid references students(id) on delete cascade,
  score         int,
  comment       text,
  entered_by    uuid references profiles(id),
  updated_at    timestamptz default now(),
  primary key (assessment_id, student_id)
);

-- Attendance (class teacher roll call) — used for attendance_pct
create table attendance (
  id          uuid primary key default gen_random_uuid(),
  student_id  uuid references students(id) on delete cascade,
  term_id     uuid references terms(id),
  on_date     date not null,
  present     boolean not null,
  marked_by   uuid references profiles(id),
  unique (student_id, on_date)
);

-- ---------- Clinic (Nurse) ----------
create type visit_outcome as enum ('discharged','observing','followUp','referred');

create table clinic_visits (
  id                 uuid primary key default gen_random_uuid(),
  student_id         uuid references students(id) on delete cascade,
  visited_at         timestamptz not null default now(),
  complaint          text not null,
  notes              text,
  vitals             jsonb default '[]',          -- [{label,value}]
  treatment          text,
  outcome            visit_outcome default 'discharged',
  follow_up_note     text,
  referral_facility  text,
  recorded_by        uuid references profiles(id),
  recorded_by_name   text,
  created_at         timestamptz default now()
);

-- ---------- Kitchen (Cook) ----------
create table menus (
  menu_date       date primary key,
  breakfast       text, breakfast_side text,
  lunch           text, lunch_side     text,
  supper          text, supper_side    text,
  published_by    uuid references profiles(id),
  published_at    timestamptz default now()
);

-- ---------- Events & documents ----------
create type event_category as enum ('academic','coCurricular','community');

create table events (
  id         uuid primary key default gen_random_uuid(),
  title      text not null,
  starts_at  timestamptz not null,
  ends_at    timestamptz,
  venue      text,
  audience   text,
  category   event_category default 'academic',
  highlight  boolean default false,
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);

create table documents (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  subtitle    text,
  url         text not null,
  student_id  uuid references students(id) on delete cascade, -- null = school-wide
  created_by  uuid references profiles(id),
  created_at  timestamptz default now()
);

-- ---------- Notices (system generated) ----------
create type notice_kind as enum ('payment','clinic','academics','event','general');

create table notices (
  id            uuid primary key default gen_random_uuid(),
  recipient_id  uuid references profiles(id) on delete cascade,
  student_id    uuid references students(id) on delete set null,
  kind          notice_kind not null,
  title         text not null,
  subtitle      text,
  amount        bigint,
  read          boolean default false,
  created_at    timestamptz default now()
);

-- FCM device tokens (alerts go out via Firebase, data lives here)
create table device_tokens (
  user_id    uuid references profiles(id) on delete cascade,
  token      text not null,
  platform   text,
  updated_at timestamptz default now(),
  primary key (user_id, token)
);

-- ---------- Summary view for the parent hero card ----------
create or replace view v_student_summary as
select
  s.id as student_id,
  coalesce(
    round(100.0 * sum(case when a.present then 1 else 0 end) / nullif(count(a.id),0), 0),
    0
  ) as attendance_pct,
  rc.position,
  rc.class_size,
  (select count(*) from clinic_visits cv
     join terms t on t.is_current
    where cv.student_id = s.id and cv.visited_at >= t.starts_on) as clinic_visits
from students s
left join terms t on t.is_current
left join attendance a on a.student_id = s.id and a.term_id = t.id
left join lateral (
  select position, class_size from report_cards r
  where r.student_id = s.id and r.status = 'published'
  order by published_at desc limit 1
) rc on true
group by s.id, rc.position, rc.class_size;

-- ============================================================
-- Triggers: every write by another role fans out a notice to guardians
-- ============================================================
create or replace function notify_guardians(sid uuid, k notice_kind, t text, st text, amt bigint)
returns void language plpgsql security definer as $$
begin
  insert into notices (recipient_id, student_id, kind, title, subtitle, amount)
  select guardian_id, sid, k, t, st, amt from student_guardians where student_id = sid;
end $$;

create or replace function trg_payment_notice() returns trigger language plpgsql as $$
begin
  perform notify_guardians(new.student_id, 'payment',
    'Receipt ' || new.receipt_no,
    initcap(new.method::text) || ' · ' || to_char(new.paid_at, 'DD Mon, HH24:MI'),
    new.amount);
  return new;
end $$;
create trigger payments_notice after insert on payments
  for each row execute function trg_payment_notice();

create or replace function trg_clinic_notice() returns trigger language plpgsql as $$
begin
  perform notify_guardians(new.student_id, 'clinic',
    'Clinic: ' || new.complaint,
    coalesce(new.recorded_by_name,'Clinic') || ' · ' || to_char(new.visited_at, 'DD Mon, HH24:MI'),
    null);
  return new;
end $$;
create trigger clinic_notice after insert on clinic_visits
  for each row execute function trg_clinic_notice();

create or replace function trg_report_published() returns trigger language plpgsql as $$
begin
  if new.status = 'published' and (old.status is distinct from 'published') then
    perform notify_guardians(new.student_id, 'academics',
      'Report card released · ' || coalesce(new.term_label,''),
      'Available in app', null);
  end if;
  return new;
end $$;
create trigger report_published after update on report_cards
  for each row execute function trg_report_published();

-- ============================================================
-- Row Level Security
-- ============================================================
alter table profiles            enable row level security;
alter table user_roles          enable row level security;
alter table terms               enable row level security;
alter table students            enable row level security;
alter table student_guardians   enable row level security;
alter table fee_lines           enable row level security;
alter table payments            enable row level security;
alter table payment_channels    enable row level security;
alter table report_cards        enable row level security;
alter table report_card_results enable row level security;
alter table assessments         enable row level security;
alter table marks               enable row level security;
alter table attendance          enable row level security;
alter table clinic_visits       enable row level security;
alter table menus               enable row level security;
alter table events              enable row level security;
alter table documents           enable row level security;
alter table notices             enable row level security;
alter table device_tokens       enable row level security;

-- profiles: read own; admins read all
create policy "own profile"   on profiles for select using (id = auth.uid() or has_role('admin','director','registrar','bursar','dos','nurse'));
create policy "update own"    on profiles for update using (id = auth.uid());
create policy "roles read"    on user_roles for select using (user_id = auth.uid() or has_role('admin','director'));
create policy "roles manage"  on user_roles for all using (has_role('admin','director'));

-- terms & channels: everyone signed-in reads; director/registrar/bursar write
create policy "terms read"     on terms for select using (auth.uid() is not null);
create policy "terms write"    on terms for all using (has_role('director','registrar','admin'));
create policy "channels read"  on payment_channels for select using (auth.uid() is not null);
create policy "channels write" on payment_channels for all using (has_role('bursar','admin'));

-- students: guardians see own; school staff see all; registrar writes
create policy "students read"  on students for select using (
  is_guardian_of(id) or has_role('teacher','staff','director','bursar','dos','nurse','cook','registrar','admin'));
create policy "students write" on students for all using (has_role('registrar','admin','director'));
create policy "guardians read" on student_guardians for select using (
  guardian_id = auth.uid() or has_role('registrar','admin','director','bursar','dos'));
create policy "guardians write" on student_guardians for all using (has_role('registrar','admin'));

-- fees: guardians read own child; bursar/director read all + write
create policy "fees read"      on fee_lines for select using (is_guardian_of(student_id) or has_role('bursar','director','admin'));
create policy "fees write"     on fee_lines for all using (has_role('bursar','admin'));
create policy "payments read"  on payments for select using (is_guardian_of(student_id) or has_role('bursar','director','admin'));
create policy "payments write" on payments for all using (has_role('bursar','admin'));

-- academics: parents only see PUBLISHED reports of own child
create policy "reports read"   on report_cards for select using (
  (is_guardian_of(student_id) and status = 'published') or has_role('teacher','dos','director','admin'));
create policy "reports write"  on report_cards for all using (has_role('dos','director','admin'));
create policy "results read"   on report_card_results for select using (
  exists (select 1 from report_cards rc where rc.id = report_card_id
          and ((is_guardian_of(rc.student_id) and rc.status='published') or has_role('teacher','dos','director','admin'))));
create policy "results write"  on report_card_results for all using (has_role('dos','director','admin'));
create policy "assess read"    on assessments for select using (has_role('teacher','dos','director','admin'));
create policy "assess write"   on assessments for all using (has_role('teacher','dos','admin'));
create policy "marks read"     on marks for select using (has_role('teacher','dos','director','admin'));
-- 7-day lock: teachers may only write before locks_at; DOS may override
create policy "marks write"    on marks for all using (
  has_role('dos','admin') or
  (has_role('teacher') and exists (select 1 from assessments a where a.id = assessment_id and now() < a.locks_at)));
create policy "attend read"    on attendance for select using (is_guardian_of(student_id) or has_role('teacher','dos','director','admin','registrar'));
create policy "attend write"   on attendance for all using (has_role('teacher','dos','admin'));

-- clinic: least privilege
create policy "clinic read"    on clinic_visits for select using (is_guardian_of(student_id) or has_role('nurse','teacher','director','admin'));
create policy "clinic write"   on clinic_visits for all using (has_role('nurse','admin'));

-- kitchen, events, documents
create policy "menus read"     on menus for select using (auth.uid() is not null);
create policy "menus write"    on menus for all using (has_role('cook','director','admin'));
create policy "events read"    on events for select using (auth.uid() is not null);
create policy "events write"   on events for all using (has_role('director','registrar','admin'));
create policy "docs read"      on documents for select using (
  student_id is null or is_guardian_of(student_id) or has_role('registrar','bursar','director','admin'));
create policy "docs write"     on documents for all using (has_role('registrar','bursar','director','admin'));

-- notices: recipient only
create policy "notices read"   on notices for select using (recipient_id = auth.uid());
create policy "notices update" on notices for update using (recipient_id = auth.uid());
create policy "tokens own"     on device_tokens for all using (user_id = auth.uid());
