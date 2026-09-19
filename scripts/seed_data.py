#!/usr/bin/env python3
"""Seed demo data into Supabase using the ids from /tmp/demo_users.json.

Idempotent-ish: wipes and re-inserts demo rows (all public tables), keeps auth users.
Run AFTER migrations 0001..0003 and scripts/seed_users.py.
"""
import json
import sys
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from db import connect, load_env  # noqa: E402

U = json.loads(Path("/tmp/demo_users.json").read_text())
uid = {k: v["id"] for k, v in U.items()}
EAT = timezone(timedelta(hours=3))
now = datetime.now(EAT)
today = now.date()
monday = today - timedelta(days=today.weekday())

TERM = "10000000-0000-0000-0000-000000000002"
FENCE = "40000000-0000-0000-0000-000000000001"


def S(id_):  # student uuid from short number
    return f"20000000-0000-0000-0000-{id_:012d}"


def C(n):  # class uuid
    return f"50000000-0000-0000-0000-{n:012d}"


def SUB(n):
    return f"60000000-0000-0000-0000-{n:012d}"


def G(n):  # extra guardian / staff ids (real auth users created by seed_users.py)
    return uid[f"g{n}" if n < 20 else f"t{n}"]


def main():
    conn = connect(load_env())
    cur = conn.cursor()

    print("wiping demo rows…")
    cur.execute("""
      truncate audit_log, medicine_issues, medicine_stock, issue_vouchers, stock_items, purchase_orders,
        requisition_lines, requisitions, staff_alerts, timesheets, staff_attendance_events, geofences,
        timetable_slots, marks, assessments, teaching_assignments, notices, device_tokens, documents, events,
        menus, clinic_visits, attendance, report_card_results, report_cards, payment_channels, payments,
        fee_lines, student_guardians, students, subjects, classes, staff_profiles, user_roles, terms
      restart identity cascade;
      delete from profiles;
    """)

    # ---- profiles + roles -------------------------------------------------
    print("profiles…")
    for k, v in U.items():
        cur.execute("insert into profiles (id, full_name, title, phone, email) values (%s,%s,%s,%s,%s)",
                    (v["id"], v["full_name"], v["title"], v["phone"], v["email"]))
        for r in v["roles"]:
            cur.execute("insert into user_roles values (%s,%s)", (v["id"], r))
    # ---- term ---------------------------------------------------------------
    cur.execute("insert into terms (id, year, number, starts_on, ends_on, fees_due_on, is_current) values (%s,2026,2,'2026-05-25','2026-08-21',%s,true)",
                (TERM, today + timedelta(days=15)))

    # ---- classes & subjects -------------------------------------------------
    print("classes, subjects…")
    classes = [(1, "S1 North", 1, "North", uid["dos"]), (2, "S2 East", 2, "East", uid["teacher"]), (3, "S2 West", 2, "West", G(21)),
               (4, "S2 South", 2, "South", None), (5, "S2 North", 2, "North", None), (6, "S3 East", 3, "East", None),
               (7, "S3 West", 3, "West", None), (8, "S3 North", 3, "North", None), (9, "S4 East", 4, "East", G(21)),
               (10, "S5 B", 5, "B", None), (11, "S6 A", 6, "A", G(20))]
    for n, name, lvl, stream, ct in classes:
        cur.execute("insert into classes (id, name, level, stream, class_teacher_id, capacity) values (%s,%s,%s,%s,%s,40)", (C(n), name, lvl, stream, ct))
    subjects = [(1, "MAT", "Mathematics"), (2, "ENG", "English"), (3, "BIO", "Biology"), (4, "CHE", "Chemistry"), (5, "PHY", "Physics"),
                (6, "HIS", "History"), (7, "KIS", "Kiswahili"), (8, "CRE", "CRE"), (9, "GEO", "Geography")]
    for n, code, name in subjects:
        cur.execute("insert into subjects (id, code, name) values (%s,%s,%s)", (SUB(n), code, name))

    # ---- students -------------------------------------------------------------
    print("students…")
    students = [
        # id, adm, first, surname, class_n, house, boarder, dorm, dob, guardian
        (478, "TGS/2024/00478", "Aisha", "Nakato", 2, "Green", True, "Kwagala dormitory, bed 14", "2011-03-14", uid["parent"]),
        (612, "TGS/2025/00612", "Grace", "Nakato", 1, "Blue", True, "Kisubi dormitory, bed 3", "2012-09-02", uid["parent"]),
        (512, "TGS/2024/00512", "Prossy", "Akello", 3, "Blue", True, "Kwagala dormitory, bed 22", "2011-06-20", G(1)),
        (13, "TGS/2021/00013", "Winnie", "Byaruhanga", 11, "White", False, None, "2007-11-05", G(2)),
        (301, "TGS/2023/00301", "Esther", "Kembabazi", 8, "Red", True, "Nsibirwa dormitory, bed 9", "2010-02-11", G(3)),
        (521, "TGS/2024/00521", "Angel", "Namuli", 4, "Green", True, "Kwagala dormitory, bed 31", "2011-08-30", G(4)),
        (159, "TGS/2022/00159", "Mercy", "Lamunu", 10, "Red", True, "Nsibirwa dormitory, bed 2", "2008-04-17", G(5)),
        (218, "TGS/2023/00218", "Patience", "Ssenoga", 6, "White", False, None, "2010-01-25", G(6)),
        (87, "TGS/2022/00087", "Doreen", "Ssekabira", 9, "Blue", True, "Kisubi dormitory, bed 18", "2009-07-09", G(7)),
        (219, "TGS/2023/00219", "Kevin", "Okello", 7, "Red", True, "Nsibirwa dormitory, bed 14", "2010-05-03", G(8)),
        # S3 East roster for marks
        (288, "TGS/2023/00288", "Miriam", "Namara", 6, "Green", True, "Nsibirwa dormitory, bed 20", "2010-03-01", G(1)),
        (214, "TGS/2023/00214", "Betty", "Ssebugwawo", 6, "Blue", True, "Nsibirwa dormitory, bed 21", "2010-06-12", G(3)),
        (233, "TGS/2023/00233", "Naome", "Tumwesigye", 6, "Red", False, None, "2010-09-09", G(4)),
        # teacher-as-parent child
        (700, "TGS/2025/00700", "Ruth", "Ssekandi", 1, "Green", False, None, "2012-12-01", uid["teacher"]),
    ]
    for sid, adm, fn, sn, cn, house, b, dorm, dob, gid in students:
        cname = next(c[1] for c in classes if c[0] == cn)
        cur.execute("""insert into students (id, admission_no, first_name, surname, class_id, class_name, house, is_boarder, dormitory, date_of_birth, admitted_on)
                       values (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""", (S(sid), adm, fn, sn, C(cn), cname, house, b, dorm, dob, "2024-02-03"))
        cur.execute("insert into student_guardians values (%s,%s,'mother',true)", (S(sid), gid))

    # ---- fees -------------------------------------------------------------------
    print("fees…")
    for sid, *_r in students:
        b = _r[5]
        cur.execute("insert into fee_lines (student_id, term_id, label, amount, created_by) values (%s,%s,'Tuition',1200000,%s)", (S(sid), TERM, uid["bursar"]))
        if b:
            cur.execute("insert into fee_lines (student_id, term_id, label, amount, created_by) values (%s,%s,'Boarding',450000,%s)", (S(sid), TERM, uid["bursar"]))
        cur.execute("insert into fee_lines (student_id, term_id, label, amount, created_by) values (%s,%s,'Lunch programme',180000,%s)", (S(sid), TERM, uid["bursar"]))
    cur.execute("insert into fee_lines (student_id, term_id, label, amount, created_by) values (%s,%s,'Uniforms',70000,%s)", (S(478), TERM, uid["bursar"]))

    pays = [
        (478, "R-2026-0611", 1100000, "bank", "Stanbic · DEP 4471", datetime(2026, 5, 28, 10, 5, tzinfo=EAT)),
        (478, "R-2026-0891", 350000, "mtn", "MM 8813402771", now.replace(hour=9, minute=12)),
        (612, "R-2026-0702", 1830000, "bank", None, datetime(2026, 6, 2, 11, 40, tzinfo=EAT)),
        (512, "R-2026-0640", 1830000, "mtn", None, datetime(2026, 5, 30, 8, 2, tzinfo=EAT)),
        (13, "R-2026-0655", 1290000, "airtel", None, datetime(2026, 6, 1, 15, 22, tzinfo=EAT)),
        (301, "R-2026-0660", 1830000, "bank", None, datetime(2026, 6, 1, 9, 0, tzinfo=EAT)),
        (521, "R-2026-0701", 1445000, "mtn", None, datetime(2026, 6, 4, 12, 30, tzinfo=EAT)),
        (159, "R-2026-0688", 1830000, "bank", None, datetime(2026, 6, 3, 10, 12, tzinfo=EAT)),
        (218, "R-2026-0720", 1380000, "cash", None, datetime(2026, 6, 6, 14, 0, tzinfo=EAT)),
        (87, "R-2026-0733", 490000, "mtn", None, datetime(2026, 6, 10, 9, 45, tzinfo=EAT)),
        (219, "R-2026-0750", 910000, "airtel", None, datetime(2026, 6, 12, 11, 15, tzinfo=EAT)),
        (288, "R-2026-0760", 1830000, "bank", None, datetime(2026, 6, 12, 11, 15, tzinfo=EAT)),
        (214, "R-2026-0761", 900000, "mtn", None, datetime(2026, 6, 13, 11, 15, tzinfo=EAT)),
        (233, "R-2026-0762", 1380000, "bank", None, datetime(2026, 6, 14, 11, 15, tzinfo=EAT)),
        (700, "R-2026-0770", 1380000, "mtn", None, datetime(2026, 6, 15, 9, 0, tzinfo=EAT)),
    ]
    # disable notice trigger during seed so guardians don't get 15 receipts; we add curated notices after
    cur.execute("alter table payments disable trigger payments_notice")
    cur.execute("alter table payments disable trigger audit_payments")
    for sid, rn, amt, m, ref, at in pays:
        cur.execute("insert into payments (student_id, term_id, receipt_no, amount, method, reference, paid_at, posted_by) values (%s,%s,%s,%s,%s,%s,%s,%s)",
                    (S(sid), TERM, rn, amt, m, ref, at, uid["bursar"]))
    cur.execute("alter table payments enable trigger payments_notice")
    cur.execute("alter table payments enable trigger audit_payments")

    cur.execute("""insert into payment_channels (method, title, instruction, sort_order) values
      ('mtn','MTN Mobile Money','Dial *165# · school code 402108',1),
      ('airtel','Airtel Money','Merchant code 402108',2),
      ('bank','Stanbic Bank deposit','A/C 9030002187 · TGS Ltd',3)""")

    # ---- teaching, timetable -----------------------------------------------------------
    print("teaching assignments, timetable…")
    ta = [(uid["teacher"], 6, 5), (uid["teacher"], 7, 5), (uid["teacher"], 2, 1), (uid["teacher"], 5, 1),
          (G(20), 11, 1), (G(21), 9, 2), (G(21), 3, 2), (uid["dos"], 1, 4), (G(24), 8, 9)]
    for t, c, s in ta:
        cur.execute("insert into teaching_assignments (teacher_id, class_id, subject_id, term_id) values (%s,%s,%s,%s)", (t, C(c), SUB(s), TERM))
    slots = [("07:30", "08:15", 7, 5, None, "Lab 2"), ("08:15", "09:00", 6, 5, None, "Lab 2"), ("09:00", "09:45", 2, 1, None, "Room 14"),
             ("10:00", "10:45", None, None, "Break duty", "Green quadrant"), ("11:30", "12:15", 5, 1, None, "Room 08"),
             ("14:00", "15:00", 6, 5, "Physics · S3 East (double)", "Lab 2"), ("15:45", "17:00", None, None, "Prep · S4 mock revision", "Library")]
    for wd in range(1, 6):
        for st, en, c, s, title, room in slots:
            cur.execute("insert into timetable_slots (term_id, weekday, starts_at, ends_at, teacher_id, class_id, subject_id, title, room) values (%s,%s,%s,%s,%s,%s,%s,%s,%s)",
                        (TERM, wd, st, en, uid["teacher"], C(c) if c else None, SUB(s) if s else None, title, room))

    # ---- assessments & marks ---------------------------------------------------------------
    print("assessments, marks…")
    cur.execute("insert into assessments (id, term_id, class_id, subject_id, class_name, subject, title, out_of, assessed_on, teacher_id) values ('30000000-0000-0000-0000-000000000101',%s,%s,%s,'S3 East','Physics','CAT 1',30,%s,%s)",
                (TERM, C(6), SUB(5), today - timedelta(days=21), uid["teacher"]))
    cur.execute("insert into assessments (id, term_id, class_id, subject_id, class_name, subject, title, out_of, assessed_on, teacher_id) values ('30000000-0000-0000-0000-000000000102',%s,%s,%s,'S3 East','Physics','CAT 2',40,%s,%s)",
                (TERM, C(6), SUB(5), today - timedelta(days=2), uid["teacher"]))
    cur.execute("insert into assessments (id, term_id, class_id, subject_id, class_name, subject, title, out_of, assessed_on, teacher_id) values ('30000000-0000-0000-0000-000000000103',%s,%s,%s,'S2 East','Mathematics','CAT 2',40,%s,%s)",
                (TERM, C(2), SUB(1), today - timedelta(days=1), uid["teacher"]))
    cur.execute("alter table marks disable trigger audit_marks")
    for sid, sc, cm in [(218, 32, "Strong grasp of mechanics"), (288, 24, "Needs more practice"), (214, 22, "Attend consultation"), (233, 30, "Neat presentation")]:
        cur.execute("insert into marks values ('30000000-0000-0000-0000-000000000102',%s,%s,%s,%s,now())", (S(sid), sc, cm, uid["teacher"]))
    cur.execute("alter table marks enable trigger audit_marks")

    # ---- attendance (learners) ---------------------------------------------------------------
    print("attendance…")
    import random
    random.seed(7)
    rows = []
    for sid, *_r in students:
        d = date(2026, 5, 25)
        while d <= today:
            if d.weekday() < 5:
                rows.append((S(sid), TERM, d, random.random() > (0.04 if sid != 87 else 0.12), uid["teacher"]))
            d += timedelta(days=1)
    cur.executemany("insert into attendance (student_id, term_id, on_date, present, marked_by) values (%s,%s,%s,%s,%s) on conflict do nothing", rows)

    # ---- report cards --------------------------------------------------------------------------
    print("report cards…")
    def rc(rid, sid, cn, pos, size, teacher, comment, status, results, pub=None):
        cur.execute("""insert into report_cards (id, student_id, term_id, term_label, class_name, position, class_size, class_teacher_name, class_teacher_comment, status, published_at, published_by)
                       values (%s,%s,%s,'Term 2 · 2026',%s,%s,%s,%s,%s,%s,%s,%s)""",
                    (rid, S(sid), TERM, next(c[1] for c in classes if c[0] == cn), pos, size, teacher, comment, status, pub, uid["dos"] if pub else None))
        for i, (subj, cat, ex, gr) in enumerate(results, 1):
            cur.execute("insert into report_card_results (report_card_id, subject, cat_score, exam_score, grade, sort_order) values (%s,%s,%s,%s,%s,%s)", (rid, subj, cat, ex, gr, i))
    cur.execute("alter table report_cards disable trigger report_published")
    cur.execute("alter table report_cards disable trigger audit_reports")
    rc("30000000-0000-0000-0000-000000000001", 478, 2, 12, 78, "Ms. Kabuye R.",
       "Aisha is a diligent and self-motivated girl. She should continue to work on the presentation of her Physics practicals. Well done this term.",
       "published", [("Mathematics", 32, 54, "D1"), ("English", 28, 48, "D2"), ("Biology", 30, 50, "D1"), ("Chemistry", 27, 44, "D2"),
                     ("Physics", 25, 42, "D2"), ("History", 31, 51, "D1"), ("Kiswahili", 29, 47, "D2"), ("CRE", 33, 55, "D1")], pub=datetime(2026, 7, 9, tzinfo=EAT))
    rc("30000000-0000-0000-0000-000000000002", 612, 1, 4, 84, "Mr. Ochieng L.",
       "Grace has settled in very well and leads by example. Keep it up.", "review",
       [("Mathematics", 36, 56, "D1"), ("English", 34, 52, "D1"), ("Biology", 31, 49, "D1"), ("Geography", 30, 46, "D2"), ("Kiswahili", 33, 50, "D1")])
    rc("30000000-0000-0000-0000-000000000003", 512, 3, 8, 76, "Ms. Nabbosa J.",
       "Prossy participates actively in class. More practice in Mathematics recommended.", "review",
       [("Mathematics", 24, 40, "C3"), ("English", 33, 51, "D1"), ("Biology", 29, 47, "D2")])
    cur.execute("alter table report_cards enable trigger report_published")
    cur.execute("alter table report_cards enable trigger audit_reports")

    # ---- clinic ----------------------------------------------------------------------------------
    print("clinic…")
    cur.execute("alter table clinic_visits disable trigger clinic_notice")
    cur.execute("alter table clinic_visits disable trigger audit_clinic")
    visits = [
        (478, now.replace(hour=10, minute=24), "Headache · mild fever", "Complaining of headache and mild fever. Paracetamol 500 mg administered. Advised rest until lunch. Returned to class after break.",
         '[{"label":"Temp","value":"37.9°C"},{"label":"BP","value":"108/68"},{"label":"Pulse","value":"88"},{"label":"Wt","value":"46 kg"}]', "Paracetamol 500 mg", "followUp", "Follow up 24 h", None),
        (512, now.replace(hour=11, minute=2), "Mild fever · 38.1°C", "Under observation in the sanatorium. Fluids given.", '[{"label":"Temp","value":"38.1°C"},{"label":"Pulse","value":"92"}]', None, "observing", None, None),
        (301, now.replace(hour=11, minute=44), "Minor scrape", "Dressed · returned to class.", "[]", None, "discharged", None, None),
        (13, now.replace(hour=13, minute=5), "Ophthalmology follow-up", "Referred to Uganda Medical Centre with parent consent.", "[]", None, "referred", None, "Uganda Medical Centre"),
        (478, datetime(2026, 6, 21, 14, 11, tzinfo=EAT), "Minor cut · left knee", "Grazed knee during sports. Cleaned, dressed, and returned to games with plaster. No further action needed.",
         '[{"label":"Temp","value":"36.6°C"},{"label":"Wound","value":"Superficial"}]', None, "discharged", None, None),
    ]
    for sid, at, comp, notes, vit, treat, out, fu, fac in visits:
        cur.execute("""insert into clinic_visits (student_id, visited_at, complaint, notes, vitals, treatment, outcome, follow_up_note, referral_facility, recorded_by, recorded_by_name)
                       values (%s,%s,%s,%s,%s::jsonb,%s,%s,%s,%s,%s,'Nurse Alice N.')""", (S(sid), at, comp, notes, vit, treat, out, fu, fac, uid["nurse"]))
    cur.execute("alter table clinic_visits enable trigger clinic_notice")
    cur.execute("alter table clinic_visits enable trigger audit_clinic")
    cur.execute("""insert into medicine_stock (name, batch, expires_on, qty, unit, reorder_at) values
      ('Paracetamol 500 mg','BATCH-2026-041','2027-07-31',48,'tab',200), ('ORS sachets','BATCH-2026-018','2027-12-31',9,'pk',40),
      ('Amoxicillin 250 mg','BATCH-2026-033','2028-03-31',120,'cap',100), ('Cetirizine 10 mg','BATCH-2026-021','2028-06-30',78,'tab',40),
      ('Sanitary pads (regular)','Welfare programme',null,124,'pk',60), ('Bandage · elastic','BATCH-2026-009','2029-11-30',18,'rolls',10)""")

    # ---- kitchen, events, documents -------------------------------------------------------------------
    print("menus, events, documents…")
    wk = [("Porridge · millet", "Milk tea, bread", "Posho & beans", "Steamed cabbage", "Rice & meat stew", "Greens, fruit"),
          ("Porridge · maize", "Milk tea, bread", "Matoke & groundnut", "Boiled greens", "Posho & beans", "Fruit"),
          ("Porridge · millet", "Milk tea, bread", "Posho & beans", "Steamed cabbage", "Rice & fish stew", "Sukuma wiki"),
          ("Porridge · maize", "Milk tea, bread", "Matoke & beef stew", "Boiled greens", "Posho & silverfish", "Fruit"),
          ("Porridge · millet", "Milk tea, bread", "Rice & bean stew", "Cabbage salad", "Matoke & meat", "Watermelon"),
          ("Bread & tea", "Boiled eggs", "Posho & beans", "Greens", "Rice & beans", "Fruit"),
          ("Porridge · millet", "Bread", "Matoke & groundnut", "Greens", "Posho & beef", "Fruit")]
    for i, m in enumerate(wk):
        cur.execute("insert into menus (menu_date, breakfast, breakfast_side, lunch, lunch_side, supper, supper_side, published_by) values (%s,%s,%s,%s,%s,%s,%s,%s)",
                    (monday + timedelta(days=i), *m, uid["cook"]))
    events = [
        ("S4 Mock paper 1 · Mathematics", now.replace(hour=8, minute=30) + timedelta(days=1), now.replace(hour=11, minute=0) + timedelta(days=1), "Main hall", None, "academic", False),
        ("Inter-house MDD final", now.replace(hour=14, minute=0) + timedelta(days=3), None, "Assembly hall", None, "coCurricular", False),
        ("Career day", now.replace(hour=9, minute=0) + timedelta(days=13), None, "Main hall", None, "coCurricular", False),
        ("Fees deadline", now.replace(hour=17, minute=0) + timedelta(days=15), None, "Bursar", None, "academic", False),
        ("Term 2 Visitation Day", now.replace(hour=10, minute=0) + timedelta(days=18), now.replace(hour=14, minute=0) + timedelta(days=18), "School hall", "Boarding parents", "community", True),
        ("Report cards released", now.replace(hour=8, minute=0) + timedelta(days=19), None, "Available in app", None, "academic", False),
    ]
    for t, s, e, v, a, c, h in events:
        cur.execute("insert into events (title, starts_at, ends_at, venue, audience, category, highlight, created_by) values (%s,%s,%s,%s,%s,%s,%s,%s)", (t, s, e, v, a, c, h, uid["registrar"]))
    cur.execute("""insert into documents (title, subtitle, url, student_id, created_by) values
      ('Term 2 fees breakdown','PDF · 340 KB','https://example.com/fees-t2-2026.pdf',null,%s),
      ('School calendar 2026','PDF · 220 KB','https://example.com/calendar-2026.pdf',null,%s),
      ('Parent handbook · 2026 ed.','PDF · 1.4 MB','https://example.com/handbook-2026.pdf',null,%s),
      ('Safe release · pickup consent','Signed 03 Feb 2024','https://example.com/consent-00478.pdf',%s,%s)""",
                (uid["registrar"], uid["registrar"], uid["registrar"], S(478), uid["registrar"]))

    # curated notices for the demo parent
    cur.execute("insert into notices (recipient_id, student_id, kind, title, subtitle, amount, created_at) values (%s,%s,'payment','Receipt R-2026-0891',%s,350000,%s)",
                (uid["parent"], S(478), f"MTN Mobile Money · {now.strftime('%d %b')}, 09:12", now.replace(hour=9, minute=12)))
    cur.execute("insert into notices (recipient_id, student_id, kind, title, subtitle, created_at) values (%s,%s,'clinic','Clinic: headache, paracetamol given',%s,%s)",
                (uid["parent"], S(478), f"Nurse Alice N. · {now.strftime('%d %b')}, 10:24", now.replace(hour=10, minute=24)))
    cur.execute("insert into notices (recipient_id, kind, title, subtitle, created_at) values (%s,'event','Term 2 Visitation Day','School hall · 10:00–14:00',%s)",
                (uid["parent"], now - timedelta(days=1)))

    # ---- staff, geofence, attendance events, alerts ----------------------------------------------------
    print("staff, geofence, attendance events…")
    staff = [(uid["teacher"], "STAFF/2021/041", "Physics", "Teacher · Class teacher S2 East"), (uid["nurse"], "STAFF/2019/012", "Clinic", "School nurse"),
             (uid["cook"], "STAFF/2018/007", "Kitchen", "Head cook"), (uid["dos"], "STAFF/2016/003", "Academics", "Director of Studies"),
             (uid["bursar"], "STAFF/2017/004", "Finance", "Bursar"), (uid["registrar"], "STAFF/2020/030", "Administration", "Registrar"),
             (uid["director"], "STAFF/2010/001", "Administration", "Director"), (G(20), "STAFF/2015/019", "Mathematics", "Teacher · S6"),
             (G(21), "STAFF/2019/027", "English", "Teacher · S4"), (G(22), "STAFF/2014/011", "Boarding", "Matron · Kwagala"),
             (G(23), "STAFF/2012/006", "Transport", "Driver"), (G(24), "STAFF/2022/044", "Geography", "Teacher · S3")]
    for sid, no, dep, title in staff:
        cur.execute("insert into staff_profiles (user_id, staff_no, department, job_title) values (%s,%s,%s,%s)", (sid, no, dep, title))
    cur.execute("insert into geofences (id, name, lat, lng, radius_m, grace_minutes) values (%s,'Main campus',0.3476,32.5825,120,15)", (FENCE,))
    cur.execute("alter table staff_attendance_events disable trigger attendance_alerts")
    checkins = [(uid["teacher"], 7, 38, 6, 42), (uid["cook"], 5, 52, 8, 30), (uid["nurse"], 7, 14, 5, 25), (uid["dos"], 7, 22, 7, 50),
                (G(20), 7, 41, 6, 60), (G(22), 6, 44, 5, 35), (G(24), 7, 52, 9, 70), (uid["bursar"], 7, 30, 5, 40), (uid["registrar"], 7, 35, 6, 45), (uid["director"], 7, 20, 6, 20)]
    for sid, h, m, acc, dist in checkins:
        cur.execute("insert into staff_attendance_events (staff_id, geofence_id, kind, at, accuracy_m, distance_m) values (%s,%s,'auto_in',%s,%s,%s)", (sid, FENCE, now.replace(hour=h, minute=m), acc, dist))
    # Nabbosa: in, then flagged off-campus
    cur.execute("insert into staff_attendance_events (staff_id, geofence_id, kind, at, accuracy_m, distance_m) values (%s,%s,'auto_in',%s,7,55)", (G(21), FENCE, now.replace(hour=7, minute=29)))
    cur.execute("insert into staff_attendance_events (staff_id, geofence_id, kind, at, accuracy_m, distance_m) values (%s,%s,'auto_out',%s,8,420)", (G(21), FENCE, now.replace(hour=9, minute=45)))
    cur.execute("insert into staff_attendance_events (staff_id, geofence_id, kind, at, accuracy_m, distance_m) values (%s,%s,'flagged_off_campus',%s,8,420)", (G(21), FENCE, now.replace(hour=9, minute=46)))
    cur.execute("alter table staff_attendance_events enable trigger attendance_alerts")
    # previous days for the teacher's timesheet
    for i in range(1, 6):
        d = today - timedelta(days=i)
        if d.weekday() < 5 and d >= monday - timedelta(days=21):
            cur.execute("insert into staff_attendance_events (staff_id, geofence_id, kind, at, accuracy_m, distance_m) values (%s,%s,'auto_in',%s,6,40)", (uid["teacher"], FENCE, datetime(d.year, d.month, d.day, 7, 29 + i % 3, tzinfo=EAT)))
            cur.execute("insert into staff_attendance_events (staff_id, geofence_id, kind, at, accuracy_m, distance_m) values (%s,%s,'auto_out',%s,6,150)", (uid["teacher"], FENCE, datetime(d.year, d.month, d.day, 17, 4 - i % 3, tzinfo=EAT)))
    alerts = [
        (uid["teacher"], "danger", "DOS office", "Off-campus during class hours", "Ms. Nabbosa J. flagged 420 m from campus during her 09:45 lesson. Please review.", now.replace(hour=14, minute=0)),
        (uid["teacher"], "warn", "Academics", "Marks entry window closes in 5 days", "Physics S3 East CAT 2 marks lock automatically 7 days after the assessment date.", now.replace(hour=13, minute=15)),
        (uid["teacher"], "success", "System", "Auto check-in accepted", "07:38 · Inside campus geofence, ±6 m.", now.replace(hour=7, minute=38)),
        (uid["teacher"], "info", "Procurement", "Requisition #REQ-0341 approved", "Lab consumables · UGX 480,000 · Director signed off.", now - timedelta(days=1)),
        (uid["dos"], "danger", "Geofence", "Off-campus during class hours", "Ms. Nabbosa J. flagged 420 m from campus during her 09:45 lesson.", now.replace(hour=9, minute=46)),
    ]
    for r, sev, src, t, b, at in alerts:
        cur.execute("insert into staff_alerts (recipient_id, severity, source, title, body, created_at) values (%s,%s,%s,%s,%s,%s)", (r, sev, src, t, b, at))

    # ---- procurement, stores -----------------------------------------------------------------------------
    print("procurement, stores…")
    cur.execute("alter table requisitions disable trigger audit_requisitions")
    reqs = [("REQ-0347", "Lab reagents · Chemistry", "Academics", uid["dos"], "L. Ochieng (DOS)", 1240000, "bursar", 1),
            ("REQ-0346", "Kitchen · 200 kg maize flour", "Kitchen", uid["cook"], "M. Nakku (Cook)", 480000, "approved", 1),
            ("REQ-0345", "Exercise books · 12 dozen", "Stores", uid["bursar"], "Stores officer", 216000, "approved", 2),
            ("REQ-0343", "Sports uniform batch", "MDD", G(21), "MDD dept", 2860000, "rejected", 2),
            ("REQ-0342", "Diesel · school van", "Transport", G(23), "Mr. Walusansa P.", 320000, "director", 3),
            ("REQ-0341", "Lab consumables · Physics", "Academics", uid["teacher"], "B. Ssekandi", 480000, "approved", 4)]
    for ref, t, dep, rid, rname, amt, st, ago in reqs:
        cur.execute("insert into requisitions (ref, title, department, requester_id, requester_name, amount, status, created_at) values (%s,%s,%s,%s,%s,%s,%s,%s)",
                    (ref, t, dep, rid, rname, amt, st, now - timedelta(days=ago)))
    cur.execute("alter table requisitions enable trigger audit_requisitions")
    cur.execute("""insert into stock_items (sku, name, category, unit, on_hand, reorder_at) values
      ('STA-EB-096','Exercise books · 96 pg','Stationery','doz',12,20), ('STA-CHK-WHT','Chalk · white','Stationery','box',84,40),
      ('UNI-BLZ-S3','Uniform · blouse S3','Uniforms','pc',28,25), ('CLN-TP-ROLL','Toilet paper · rolls','Cleaning','roll',42,80),
      ('CLN-DET-800','Detergent · bar 800g','Cleaning','pc',64,50), ('KIT-MAZ-50K','Maize flour · sacks 50 kg','Kitchen','sk',8,6),
      ('KIT-CHR-SAC','Charcoal · sacks','Kitchen','sk',4,10), ('KIT-RCE-25K','Rice · 25 kg','Kitchen','sk',7,5)""")

    conn.commit()
    print("\nseed complete.")
    for q in ["students", "payments", "clinic_visits", "report_cards", "notices", "staff_attendance_events", "timesheets", "staff_alerts", "audit_log"]:
        cur.execute(f"select count(*) from {q}")
        print(f"  {q:26s} {cur.fetchone()[0]}")
    conn.close()


if __name__ == "__main__":
    main()
