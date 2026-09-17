-- ============================================================
-- Timbitwire Girls School — Phase 3: admin console
-- procurement (requisitions, purchase orders), stores (stock items, issue
-- vouchers), clinic medicine stock, KPI views.
-- See docs/DATA_MODEL.md §11–§13.
-- ============================================================

-- ---------- Procurement ----------
create type requisition_status as enum (
  'bursar','director','approved','poRaised','delivered','rejected'
);

create table requisitions (
  id            uuid primary key default gen_random_uuid(),
  ref           text unique not null,              -- REQ-0347
  title         text not null,
  department    text not null,
  requester_id  uuid references profiles(id),
  requester_name text,
  amount        bigint not null check (amount >= 0),
  status        requisition_status default 'bursar',
  note          text,
  created_at    timestamptz default now(),
  bursar_by     uuid references profiles(id),  bursar_at   timestamptz,
  director_by   uuid references profiles(id),  director_at timestamptz
);

create table requisition_lines (
  id              uuid primary key default gen_random_uuid(),
  requisition_id  uuid references requisitions(id) on delete cascade,
  description     text not null,
  qty             numeric not null,
  unit            text,
  unit_price      bigint not null
);

create table purchase_orders (
  id              uuid primary key default gen_random_uuid(),
  po_no           text unique not null,           -- PO-2026-019
  requisition_id  uuid unique references requisitions(id),
  supplier        text not null,
  amount          bigint not null,
  raised_by       uuid references profiles(id),
  raised_at       timestamptz default now(),
  delivered_at    timestamptz
);

-- ---------- Stores ----------
create table stock_items (
  id            uuid primary key default gen_random_uuid(),
  sku           text unique not null,             -- STA-EB-096
  name          text not null,
  category      text not null,                    -- Stationery|Kitchen|Uniforms|Cleaning
  unit          text not null,
  on_hand       numeric not null default 0,
  reorder_at    numeric not null default 0,
  unit_cost     bigint default 0
);

create table issue_vouchers (
  id           uuid primary key default gen_random_uuid(),
  voucher_no   text unique not null,              -- IV-2026-0231
  stock_item_id uuid references stock_items(id),
  qty          numeric not null check (qty > 0),
  issued_to    text not null,                     -- S3E | Kitchen | Laundry
  issued_by    uuid references profiles(id),
  issued_at    timestamptz default now()
);

create or replace function trg_issue_voucher() returns trigger language plpgsql as $$
begin
  update stock_items set on_hand = on_hand - new.qty where id = new.stock_item_id;
  return new;
end $$;
create trigger issue_voucher_decrement after insert on issue_vouchers
  for each row execute function trg_issue_voucher();

-- ---------- Clinic medicine stock ----------
create table medicine_stock (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  batch       text,
  expires_on  date,
  qty         numeric not null default 0,
  unit        text not null,
  reorder_at  numeric not null default 0
);

create table medicine_issues (
  id               uuid primary key default gen_random_uuid(),
  medicine_id      uuid references medicine_stock(id),
  clinic_visit_id  uuid references clinic_visits(id) on delete set null,
  qty              numeric not null check (qty > 0),
  issued_by        uuid references profiles(id),
  issued_at        timestamptz default now()
);

create or replace function trg_medicine_issue() returns trigger language plpgsql as $$
begin
  update medicine_stock set qty = qty - new.qty where id = new.medicine_id;
  return new;
end $$;
create trigger medicine_issue_decrement after insert on medicine_issues
  for each row execute function trg_medicine_issue();

-- ---------- KPI views ----------
create or replace view v_finance_kpis as
with t as (select id, fees_due_on from terms where is_current limit 1),
inv as (select student_id, sum(amount) invoiced from fee_lines f join t on f.term_id = t.id group by student_id),
pay as (select student_id, sum(amount) paid from payments p join t on p.term_id = t.id group by student_id),
per as (
  select s.id, coalesce(inv.invoiced,0) invoiced, coalesce(pay.paid,0) paid,
         case when coalesce(inv.invoiced,0) - coalesce(pay.paid,0) <= 0 then 'cleared'
              when now()::date > (select fees_due_on from t) then 'arrears'
              else 'partial' end status
  from students s left join inv on inv.student_id = s.id left join pay on pay.student_id = s.id
  where s.active
)
select
  sum(invoiced) invoiced, sum(paid) collected,
  count(*) filter (where status='arrears') arrears_count,
  count(*) filter (where status='partial') partial_count,
  count(*) filter (where status='cleared') cleared_count,
  (select coalesce(sum(amount),0) from payments where paid_at::date = now()::date) today
from per;

create or replace view v_student_fees as
with t as (select id from terms where is_current limit 1)
select s.id student_id, s.admission_no, s.class_name,
  coalesce((select sum(amount) from fee_lines f where f.student_id = s.id and f.term_id = (select id from t)),0) invoiced,
  coalesce((select sum(amount) from payments p where p.student_id = s.id and p.term_id = (select id from t)),0) paid
from students s where s.active;

create or replace view v_staff_presence as
select sp.user_id, p.full_name, sp.department, sp.job_title,
  e.kind last_kind, e.at last_at, e.accuracy_m, e.distance_m,
  case when e.kind in ('auto_in','manual_in') then 'inside'
       when e.kind in ('auto_out','manual_out','flagged_off_campus') then 'outside'
       else 'offDuty' end status
from staff_profiles sp
join profiles p on p.id = sp.user_id
left join lateral (
  select kind, at, accuracy_m, distance_m from staff_attendance_events
  where staff_id = sp.user_id and at::date = now()::date order by at desc limit 1
) e on true
where sp.active;

-- ---------- Audit on new tables ----------
create trigger audit_requisitions after insert or update on requisitions for each row execute function audit_row();
create trigger audit_pos          after insert or update on purchase_orders for each row execute function audit_row();
create trigger audit_vouchers     after insert on issue_vouchers for each row execute function audit_row();

-- ---------- RLS ----------
alter table requisitions      enable row level security;
alter table requisition_lines enable row level security;
alter table purchase_orders   enable row level security;
alter table stock_items       enable row level security;
alter table issue_vouchers    enable row level security;
alter table medicine_stock    enable row level security;
alter table medicine_issues   enable row level security;

-- any staff may raise a requisition; only bursar/director change status
create policy "req read"    on requisitions for select using (requester_id = auth.uid() or has_role('bursar','director','dos','admin'));
create policy "req insert"  on requisitions for insert with check (auth.uid() is not null);
create policy "req update"  on requisitions for update using (has_role('bursar','director','admin'));
create policy "reql read"   on requisition_lines for select using (exists (select 1 from requisitions r where r.id = requisition_id and (r.requester_id = auth.uid() or has_role('bursar','director','dos','admin'))));
create policy "reql write"  on requisition_lines for all using (exists (select 1 from requisitions r where r.id = requisition_id and (r.requester_id = auth.uid() or has_role('bursar','admin'))));
create policy "po read"     on purchase_orders for select using (has_role('bursar','director','admin'));
create policy "po write"    on purchase_orders for all using (has_role('bursar','admin'));

create policy "stock read"  on stock_items for select using (has_role('bursar','director','cook','registrar','admin','staff'));
create policy "stock write" on stock_items for all using (has_role('bursar','admin'));
create policy "iv read"     on issue_vouchers for select using (has_role('bursar','director','admin'));
create policy "iv write"    on issue_vouchers for insert with check (has_role('bursar','admin','staff'));

create policy "med read"    on medicine_stock for select using (has_role('nurse','director','bursar','admin'));
create policy "med write"   on medicine_stock for all using (has_role('nurse','admin'));
create policy "medi read"   on medicine_issues for select using (has_role('nurse','director','admin'));
create policy "medi write"  on medicine_issues for insert with check (has_role('nurse','admin'));
