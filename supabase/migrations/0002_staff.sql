-- ============================================================
-- Timbitwire Girls School — Phase 2: staff shell
-- classes, subjects, staff profiles, teaching assignments, timetable,
-- geofences, staff attendance events, timesheets, staff alerts, audit log.
-- See docs/DATA_MODEL.md for the full relation map.
-- ============================================================

-- ---------- Academic structure ----------
create table classes (
  id                uuid primary key default gen_random_uuid(),
  name              text unique not null,          -- S2 East
  level             int  not null check (level between 1 and 6),
  stream            text,
  class_teacher_id  uuid references profiles(id),
  capacity          int
);

create table subjects (
  id    uuid primary key default gen_random_uuid(),
  code  text unique not null,                      -- PHY
  name  text not null                              -- Physics
);

-- link students to a class row (class_name kept for display)
alter table students add column class_id uuid references classes(id);
create index on students(class_id);

create table teaching_assignments (
  id          uuid primary key default gen_random_uuid(),
  teacher_id  uuid references profiles(id) on delete cascade,
  class_id    uuid references classes(id)  on delete cascade,
  subject_id  uuid references subjects(id) on delete cascade,
  term_id     uuid references terms(id)    on delete cascade,
  unique (teacher_id, class_id, subject_id, term_id)
);

create or replace function teaches(cid uuid, sid uuid)
returns boolean language sql stable security definer as $$
  select exists (
    select 1 from teaching_assignments ta join terms t on t.id = ta.term_id
    where ta.teacher_id = auth.uid() and ta.class_id = cid and ta.subject_id = sid and t.is_current
  );
$$;

create or replace function is_class_teacher_of(cid uuid)
returns boolean language sql stable security definer as $$
  select exists (select 1 from classes where id = cid and class_teacher_id = auth.uid());
$$;

-- assessments now reference class/subject rows
alter table assessments add column class_id   uuid references classes(id);
alter table assessments add column subject_id uuid references subjects(id);

create table timetable_slots (
  id          uuid primary key default gen_random_uuid(),
  term_id     uuid references terms(id) on delete cascade,
  weekday     int  not null check (weekday between 1 and 7),
  starts_at   time not null,
  ends_at     time not null,
  teacher_id  uuid references profiles(id) on delete cascade,
  class_id    uuid references classes(id),
  subject_id  uuid references subjects(id),
  title       text,                                -- Break duty, Prep
  room        text
);
create index on timetable_slots(teacher_id, weekday);

-- ---------- Staff ----------
create table staff_profiles (
  user_id                uuid primary key references profiles(id) on delete cascade,
  staff_no               text unique not null,     -- STAFF/2021/041
  department             text,
  job_title              text,
  duty_start             time default '07:30',
  duty_end               time default '17:00',
  weekly_target_minutes  int  default 2400,
  auto_checkin           boolean default true,
  active                 boolean default true
);

-- ---------- Geofence attendance ----------
create table geofences (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  lat            double precision not null,
  lng            double precision not null,
  radius_m       int not null default 120,
  grace_minutes  int not null default 15,
  active         boolean default true
);

create type attendance_kind as enum (
  'auto_in','auto_out','manual_in','manual_out','flagged_off_campus'
);

create table staff_attendance_events (
  id              uuid primary key default gen_random_uuid(),
  staff_id        uuid references staff_profiles(user_id) on delete cascade,
  geofence_id     uuid references geofences(id),
  kind            attendance_kind not null,
  at              timestamptz not null default now(),
  lat             double precision,
  lng             double precision,
  accuracy_m      double precision,
  distance_m      double precision,
  in_duty_window  boolean default true
);
create index on staff_attendance_events(staff_id, at desc);

create table timesheets (
  staff_id        uuid references staff_profiles(user_id) on delete cascade,
  on_date         date not null,
  term_id         uuid references terms(id),
  first_in        timestamptz,
  last_out        timestamptz,
  minutes_worked  int default 0,
  late_minutes    int default 0,
  status          text default 'in_progress',      -- full_day|partial|absent|in_progress
  approved_by     uuid references profiles(id),
  approved_at     timestamptz,
  primary key (staff_id, on_date)
);

-- Recompute a day's timesheet from its events
create or replace function recompute_timesheet(p_staff uuid, p_date date)
returns void language plpgsql security definer as $$
declare
  v_first timestamptz; v_last timestamptz; v_minutes int := 0; v_late int := 0;
  v_duty time; v_grace int; v_term uuid; v_status text;
  r record; v_open timestamptz := null;
begin
  select duty_start into v_duty from staff_profiles where user_id = p_staff;
  select grace_minutes into v_grace from geofences where active limit 1;
  select id into v_term from terms where is_current limit 1;

  for r in
    select kind, at from staff_attendance_events
    where staff_id = p_staff and at::date = p_date and kind <> 'flagged_off_campus'
    order by at
  loop
    if r.kind in ('auto_in','manual_in') then
      if v_open is null then v_open := r.at; end if;
      if v_first is null then v_first := r.at; end if;
    elsif r.kind in ('auto_out','manual_out') and v_open is not null then
      v_minutes := v_minutes + extract(epoch from (r.at - v_open))::int / 60;
      v_last := r.at; v_open := null;
    end if;
  end loop;

  if v_open is not null then
    v_minutes := v_minutes + extract(epoch from (least(now(), (p_date + interval '1 day')::timestamptz) - v_open))::int / 60;
    v_status := 'in_progress';
  elsif v_first is null then v_status := 'absent';
  elsif v_minutes >= 480 then v_status := 'full_day';
  else v_status := 'partial';
  end if;

  if v_first is not null and v_duty is not null then
    v_late := greatest(0, extract(epoch from (v_first::time - v_duty))::int / 60 - coalesce(v_grace, 0));
  end if;

  insert into timesheets (staff_id, on_date, term_id, first_in, last_out, minutes_worked, late_minutes, status)
  values (p_staff, p_date, v_term, v_first, v_last, v_minutes, v_late, v_status)
  on conflict (staff_id, on_date) do update
    set first_in = excluded.first_in, last_out = excluded.last_out,
        minutes_worked = excluded.minutes_worked, late_minutes = excluded.late_minutes,
        status = excluded.status
    where timesheets.approved_at is null;   -- locked once payroll approves
end $$;

create or replace function trg_attendance_event() returns trigger language plpgsql as $$
begin
  perform recompute_timesheet(new.staff_id, new.at::date);
  return new;
end $$;
create trigger attendance_event_ts after insert on staff_attendance_events
  for each row execute function trg_attendance_event();

-- ---------- Staff alerts ----------
create table staff_alerts (
  id                uuid primary key default gen_random_uuid(),
  recipient_id      uuid references profiles(id) on delete cascade,
  severity          text not null default 'info',   -- danger|warn|success|info
  source            text,                           -- Geofence|Academics|Procurement|System
  title             text not null,
  body              text,
  related_staff_id  uuid references profiles(id),
  read              boolean default false,
  created_at        timestamptz default now()
);
create index on staff_alerts(recipient_id, created_at desc);

-- off-campus during class hours -> alert DOS + the teacher
create or replace function trg_offcampus_alert() returns trigger language plpgsql as $$
declare v_name text;
begin
  if new.kind = 'flagged_off_campus' then
    select full_name into v_name from profiles where id = new.staff_id;
    insert into staff_alerts (recipient_id, severity, source, title, body, related_staff_id)
    select ur.user_id, 'danger', 'Geofence',
           'Off-campus during class hours',
           v_name || ' flagged ' || round(new.distance_m) || ' m from campus. Please review.',
           new.staff_id
    from user_roles ur where ur.role in ('dos','director');
    insert into staff_alerts (recipient_id, severity, source, title, body)
    values (new.staff_id, 'warn', 'Geofence', 'You appear to be off-campus',
            'Detected ' || round(new.distance_m) || ' m from campus during a scheduled lesson.');
  elsif new.kind = 'auto_in' then
    insert into staff_alerts (recipient_id, severity, source, title, body)
    values (new.staff_id, 'success', 'System', 'Auto check-in accepted',
            to_char(new.at, 'HH24:MI') || ' · Inside campus geofence, ±' || round(coalesce(new.accuracy_m,0)) || ' m.');
  end if;
  return new;
end $$;
create trigger attendance_alerts after insert on staff_attendance_events
  for each row execute function trg_offcampus_alert();

-- ---------- Audit log ----------
create table audit_log (
  id         bigserial primary key,
  at         timestamptz default now(),
  actor_id   uuid references profiles(id),
  actor_name text,
  action     text not null,          -- Posted|Approved|Added|Edited|Failed|Auto check-in|...
  entity     text not null,          -- payments|marks|clinic_visits|...
  entity_id  text,
  detail     text,
  severity   text default 'info',    -- info|warn|alert
  before     jsonb,
  after      jsonb
);
create index on audit_log(at desc);

create or replace function audit_row() returns trigger language plpgsql security definer as $$
declare v_name text;
begin
  select full_name into v_name from profiles where id = auth.uid();
  insert into audit_log (actor_id, actor_name, action, entity, entity_id, before, after)
  values (auth.uid(), coalesce(v_name,'SYSTEM'), tg_op, tg_table_name,
          coalesce((case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end)->>'id',''),
          case when tg_op in ('UPDATE','DELETE') then to_jsonb(old) end,
          case when tg_op in ('INSERT','UPDATE') then to_jsonb(new) end);
  return coalesce(new, old);
end $$;

create trigger audit_payments      after insert or update or delete on payments      for each row execute function audit_row();
create trigger audit_marks         after insert or update or delete on marks         for each row execute function audit_row();
create trigger audit_clinic        after insert or update or delete on clinic_visits for each row execute function audit_row();
create trigger audit_reports       after update on report_cards                       for each row execute function audit_row();
create trigger audit_fee_lines     after insert or update or delete on fee_lines     for each row execute function audit_row();

-- ---------- Tighten marks policy now that assignments exist ----------
drop policy if exists "marks write" on marks;
create policy "marks write" on marks for all using (
  has_role('dos','admin') or
  (has_role('teacher') and exists (
     select 1 from assessments a
     where a.id = assessment_id and now() < a.locks_at and teaches(a.class_id, a.subject_id)))
);
drop policy if exists "assess write" on assessments;
create policy "assess write" on assessments for all using (
  has_role('dos','admin') or (has_role('teacher') and teaches(class_id, subject_id)));

drop policy if exists "attend write" on attendance;
create policy "attend write" on attendance for all using (
  has_role('dos','admin') or exists (
    select 1 from students s where s.id = student_id and is_class_teacher_of(s.class_id)));

-- ---------- RLS for new tables ----------
alter table classes                 enable row level security;
alter table subjects                enable row level security;
alter table teaching_assignments    enable row level security;
alter table timetable_slots         enable row level security;
alter table staff_profiles          enable row level security;
alter table geofences               enable row level security;
alter table staff_attendance_events enable row level security;
alter table timesheets              enable row level security;
alter table staff_alerts            enable row level security;
alter table audit_log               enable row level security;

create policy "classes read"   on classes  for select using (auth.uid() is not null);
create policy "classes write"  on classes  for all using (has_role('registrar','dos','admin'));
create policy "subjects read"  on subjects for select using (auth.uid() is not null);
create policy "subjects write" on subjects for all using (has_role('dos','admin'));
create policy "ta read"        on teaching_assignments for select using (teacher_id = auth.uid() or has_role('dos','director','admin'));
create policy "ta write"       on teaching_assignments for all using (has_role('dos','admin'));
create policy "tt read"        on timetable_slots for select using (teacher_id = auth.uid() or has_role('dos','director','admin'));
create policy "tt write"       on timetable_slots for all using (has_role('dos','admin'));
create policy "staff read"     on staff_profiles for select using (user_id = auth.uid() or has_role('director','bursar','dos','admin'));
create policy "staff self"     on staff_profiles for update using (user_id = auth.uid());
create policy "staff write"    on staff_profiles for all using (has_role('admin','director','registrar'));
create policy "fence read"     on geofences for select using (auth.uid() is not null);
create policy "fence write"    on geofences for all using (has_role('admin','director'));
create policy "sae read"       on staff_attendance_events for select using (staff_id = auth.uid() or has_role('dos','director','bursar','admin'));
create policy "sae insert"     on staff_attendance_events for insert with check (staff_id = auth.uid() or has_role('admin'));
create policy "ts read"        on timesheets for select using (staff_id = auth.uid() or has_role('dos','director','bursar','admin'));
create policy "ts approve"     on timesheets for update using (has_role('bursar','director','admin'));
create policy "alerts read"    on staff_alerts for select using (recipient_id = auth.uid());
create policy "alerts update"  on staff_alerts for update using (recipient_id = auth.uid());
create policy "audit read"     on audit_log for select using (has_role('director','admin'));
