-- ============================================================
-- Phase 4: student number as the universal key + app support objects
--   * students.admission_no IS the student number (unique, never changes)
--   * parents sign in with student number + PIN: one auth account per student
--     (email = <slug>@students.timbitwire.demo) linked via student_guardians
--   * RPCs / views the Flutter Supabase repositories rely on
-- ============================================================

create or replace function student_no_slug(p_no text) returns text
language sql immutable as $$
  select lower(regexp_replace(trim(p_no), '[^A-Za-z0-9]+', '-', 'g'));
$$;

create or replace function norm_student_no(p_no text) returns text
language sql immutable as $$
  select upper(regexp_replace(trim(p_no), '[\s\-]+', '/', 'g'));
$$;

-- Look a student up by number (staff, or the guardian of that student)
create or replace function student_by_no(p_no text)
returns setof students language sql stable security definer as $$
  select * from students
  where norm_student_no(admission_no) = norm_student_no(p_no)
    and (has_role('teacher','staff','director','bursar','dos','nurse','cook','registrar','admin') or is_guardian_of(id));
$$;

-- ---------- Student login accounts ----------
create table student_logins (
  student_id   uuid primary key references students(id) on delete cascade,
  login_email  text unique not null,
  auth_user_id uuid references profiles(id) on delete set null,
  pin_set_at   timestamptz,
  created_at   timestamptz default now()
);
alter table student_logins enable row level security;
create policy "logins staff read" on student_logins for select using (has_role('registrar','director','admin','bursar'));
create policy "logins write"      on student_logins for all using (has_role('registrar','admin'));

-- Enrolment queue: console inserts; provisioning script (service role) creates
-- the auth user + PIN and links guardians, so service-role never ships in the app.
create table guardian_invites (
  id             uuid primary key default gen_random_uuid(),
  student_id     uuid references students(id) on delete cascade,
  guardian_name  text not null,
  guardian_phone text not null,
  relationship   text default 'guardian',
  pin            text,
  created_by     uuid references profiles(id),
  created_at     timestamptz default now(),
  processed_at   timestamptz,
  error          text
);
alter table guardian_invites enable row level security;
create policy "invites read"  on guardian_invites for select using (has_role('registrar','director','admin'));
create policy "invites write" on guardian_invites for insert with check (has_role('registrar','admin','director'));

-- ---------- Receipts ----------
create sequence if not exists receipt_seq start 900;
create or replace function next_receipt_no() returns text
language sql volatile security definer as $$
  select 'R-' || to_char(now(), 'YYYY') || '-' || lpad(nextval('receipt_seq')::text, 4, '0');
$$;

-- Post a payment BY STUDENT NUMBER (what the bursar types)
create or replace function post_payment(p_student_no text, p_amount bigint, p_method payment_method, p_reference text default null)
returns payments language plpgsql security definer as $$
declare v_sid uuid; v_term uuid; v_row payments;
begin
  if not has_role('bursar','admin') then raise exception 'not allowed'; end if;
  select id into v_sid from students where norm_student_no(admission_no) = norm_student_no(p_student_no);
  if v_sid is null then raise exception 'Unknown student number %', p_student_no; end if;
  select id into v_term from terms where is_current limit 1;
  insert into payments (student_id, term_id, receipt_no, amount, method, reference, posted_by)
  values (v_sid, v_term, next_receipt_no(), p_amount, p_method, p_reference, auth.uid())
  returning * into v_row;
  return v_row;
end $$;

-- Enrol a student (registrar). Creates the student row, default invoice lines
-- and a guardian_invite for provisioning. Returns the student.
create or replace function enrol_student(
  p_first text, p_surname text, p_class_id uuid, p_house text, p_boarder boolean,
  p_guardian_name text, p_guardian_phone text, p_pin text)
returns students language plpgsql security definer as $$
declare v_no text; v_year text := to_char(now(),'YYYY'); v_seq int; v_row students; v_term uuid; v_cls text;
begin
  if not has_role('registrar','admin','director') then raise exception 'not allowed'; end if;
  select coalesce(max(substring(admission_no from '\d+$')::int), 0) + 1 into v_seq from students where admission_no like 'TGS/' || v_year || '/%';
  v_no := 'TGS/' || v_year || '/' || lpad(v_seq::text, 5, '0');
  select name into v_cls from classes where id = p_class_id;
  insert into students (admission_no, first_name, surname, class_id, class_name, house, is_boarder, admitted_on)
  values (v_no, p_first, p_surname, p_class_id, v_cls, p_house, p_boarder, now()::date) returning * into v_row;
  select id into v_term from terms where is_current limit 1;
  insert into fee_lines (student_id, term_id, label, amount, created_by) values (v_row.id, v_term, 'Tuition', 1200000, auth.uid());
  if p_boarder then insert into fee_lines (student_id, term_id, label, amount, created_by) values (v_row.id, v_term, 'Boarding', 450000, auth.uid()); end if;
  insert into fee_lines (student_id, term_id, label, amount, created_by) values (v_row.id, v_term, 'Lunch programme', 180000, auth.uid());
  insert into guardian_invites (student_id, guardian_name, guardian_phone, pin, created_by)
  values (v_row.id, p_guardian_name, p_guardian_phone, p_pin, auth.uid());
  return v_row;
end $$;

-- ---------- Views the app reads ----------
create or replace view v_classes as
select c.*, (select count(*) from students s where s.class_id = c.id and s.active) as size from classes c;

create or replace view v_timetable as
select t.*, c.name as class_name, sub.name as subject_name,
       (select count(*) from students s where s.class_id = t.class_id and s.active) as class_size
from timetable_slots t
left join classes c on c.id = t.class_id
left join subjects sub on sub.id = t.subject_id;

create or replace view v_teaching_assignments as
select ta.*, c.name as class_name, c.level, c.class_teacher_id, sub.code as subject_code, sub.name as subject_name,
       (select count(*) from students s where s.class_id = ta.class_id and s.active) as class_size
from teaching_assignments ta
join classes c on c.id = ta.class_id
join subjects sub on sub.id = ta.subject_id;

create or replace view v_students_admin as
select s.*, ss.attendance_pct, ss.position, ss.class_size, ss.clinic_visits,
       coalesce(f.invoiced,0) invoiced, coalesce(f.paid,0) paid,
       (select p.full_name from student_guardians sg join profiles p on p.id = sg.guardian_id
         where sg.student_id = s.id order by sg.is_primary desc limit 1) guardian_name,
       (select p.phone from student_guardians sg join profiles p on p.id = sg.guardian_id
         where sg.student_id = s.id order by sg.is_primary desc limit 1) guardian_phone
from students s
left join v_student_summary ss on ss.student_id = s.id
left join v_student_fees f on f.student_id = s.id
where s.active;

create or replace view v_clinic_visits_admin as
select cv.*, s.admission_no, s.surname || ' ' || s.first_name as student_name, s.class_name
from clinic_visits cv join students s on s.id = cv.student_id;

create or replace view v_report_cards_admin as
select rc.*, s.admission_no, s.surname || ' ' || s.first_name as student_name
from report_cards rc join students s on s.id = rc.student_id;

create or replace view v_payments_admin as
select p.*, s.admission_no, s.surname || ' ' || s.first_name as student_name, s.class_name
from payments p join students s on s.id = p.student_id;

-- marks grid: class roster with the mark for one assessment
create or replace function marks_grid(p_assessment uuid)
returns table (student_id uuid, admission_no text, full_name text, score int, comment text)
language sql stable security definer as $$
  select s.id, s.admission_no, s.surname || ' ' || s.first_name, m.score, m.comment
  from assessments a
  join students s on s.class_id = a.class_id and s.active
  left join marks m on m.assessment_id = a.id and m.student_id = s.id
  where a.id = p_assessment
    and (has_role('dos','director','admin') or teaches(a.class_id, a.subject_id))
  order by s.surname, s.first_name;
$$;

-- roll call: class roster with the day's mark (defaults present)
create or replace function roll_call(p_class uuid, p_date date)
returns table (student_id uuid, admission_no text, full_name text, present boolean)
language sql stable security definer as $$
  select s.id, s.admission_no, s.surname || ' ' || s.first_name, coalesce(a.present, true)
  from students s
  left join attendance a on a.student_id = s.id and a.on_date = p_date
  where s.class_id = p_class and s.active
    and (has_role('dos','director','admin') or is_class_teacher_of(p_class))
  order by s.surname, s.first_name;
$$;

-- Events -> notice for every guardian
create or replace function trg_event_notice() returns trigger language plpgsql as $$
begin
  insert into notices (recipient_id, kind, title, subtitle)
  select distinct guardian_id, 'event', new.title,
         coalesce(new.venue, new.audience, '') || ' · ' || to_char(new.starts_at, 'DD Mon, HH24:MI')
  from student_guardians;
  return new;
end $$;
create trigger events_notice after insert on events for each row execute function trg_event_notice();

-- Weekly timesheet helper
create or replace function my_week(p_monday date)
returns setof timesheets language sql stable security definer as $$
  select * from timesheets where staff_id = auth.uid() and on_date between p_monday and p_monday + 6 order by on_date;
$$;
create or replace function my_previous_weeks(p_count int default 3)
returns table (week_start date, minutes bigint) language sql stable security definer as $$
  select date_trunc('week', on_date)::date, sum(minutes_worked)
  from timesheets where staff_id = auth.uid() and on_date < date_trunc('week', now())::date
  group by 1 order by 1 desc limit p_count;
$$;
