-- Demo seed for the parent shell. Run AFTER 0001_init.sql.
-- Replace the guardian uuid below with a real auth.users id after you create
-- the test parent account (Auth > Users > Add user) in the Supabase dashboard.

-- 1. Guardian profile  ---------------------------------------------------
--    create the auth user first, then paste its id here:
\set guardian_id '00000000-0000-0000-0000-000000000001'

insert into profiles (id, full_name, title, phone, email)
values (:'guardian_id', 'Mukisa Josephine', 'Ms.', '+256772894001', 'mukisa.j@example.com')
on conflict (id) do nothing;
insert into user_roles values (:'guardian_id', 'parent') on conflict do nothing;

-- 2. Term ---------------------------------------------------------------
insert into terms (id, year, number, starts_on, ends_on, fees_due_on, is_current)
values ('10000000-0000-0000-0000-000000000002', 2026, 2, '2026-05-25', '2026-08-21', '2026-07-24', true)
on conflict (year, number) do nothing;

-- 3. Students -----------------------------------------------------------
insert into students (id, admission_no, first_name, surname, class_name, house, is_boarder, dormitory, date_of_birth, admitted_on) values
('20000000-0000-0000-0000-000000000478', 'TGS/2024/00478', 'Aisha', 'Nakato', 'S2 East',  'Green', true, 'Kwagala dormitory, bed 14', '2011-03-14', '2024-02-03'),
('20000000-0000-0000-0000-000000000612', 'TGS/2025/00612', 'Grace', 'Nakato', 'S1 North', 'Blue',  true, 'Kisubi dormitory, bed 3',   '2012-09-02', '2025-02-03')
on conflict (admission_no) do nothing;

insert into student_guardians values
('20000000-0000-0000-0000-000000000478', :'guardian_id', 'mother', true),
('20000000-0000-0000-0000-000000000612', :'guardian_id', 'mother', true)
on conflict do nothing;

-- 4. Fees (Bursar) ------------------------------------------------------
insert into fee_lines (student_id, term_id, label, amount) values
('20000000-0000-0000-0000-000000000478','10000000-0000-0000-0000-000000000002','Tuition',1200000),
('20000000-0000-0000-0000-000000000478','10000000-0000-0000-0000-000000000002','Boarding',450000),
('20000000-0000-0000-0000-000000000478','10000000-0000-0000-0000-000000000002','Lunch programme',180000),
('20000000-0000-0000-0000-000000000478','10000000-0000-0000-0000-000000000002','Uniforms',70000),
('20000000-0000-0000-0000-000000000612','10000000-0000-0000-0000-000000000002','Tuition',1200000),
('20000000-0000-0000-0000-000000000612','10000000-0000-0000-0000-000000000002','Boarding',450000),
('20000000-0000-0000-0000-000000000612','10000000-0000-0000-0000-000000000002','Lunch programme',180000);

insert into payments (student_id, term_id, receipt_no, amount, method, reference, paid_at) values
('20000000-0000-0000-0000-000000000478','10000000-0000-0000-0000-000000000002','R-2026-0611',1100000,'bank','Stanbic · DEP 4471','2026-05-28 10:05+03'),
('20000000-0000-0000-0000-000000000478','10000000-0000-0000-0000-000000000002','R-2026-0891',350000,'mtn','MM 8813402771','2026-07-09 09:12+03'),
('20000000-0000-0000-0000-000000000612','10000000-0000-0000-0000-000000000002','R-2026-0702',1830000,'bank',null,'2026-06-02 11:40+03');

insert into payment_channels (method, title, instruction, sort_order) values
('mtn','MTN Mobile Money','Dial *165# · school code 402108',1),
('airtel','Airtel Money','Merchant code 402108',2),
('bank','Stanbic Bank deposit','A/C 9030002187 · TGS Ltd',3);

-- 5. Report card (Teachers -> DOS published) -----------------------------
insert into report_cards (id, student_id, term_id, term_label, class_name, position, class_size, class_teacher_name, class_teacher_comment, status, published_at)
values ('30000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000478','10000000-0000-0000-0000-000000000002',
 'Term 2 · 2026','S2 East',12,78,'Ms. Kabuye R.',
 'Aisha is a diligent and self-motivated girl. She should continue to work on the presentation of her Physics practicals. Well done this term.',
 'published','2026-07-09');

insert into report_card_results (report_card_id, subject, cat_score, exam_score, grade, sort_order) values
('30000000-0000-0000-0000-000000000001','Mathematics',32,54,'D1',1),
('30000000-0000-0000-0000-000000000001','English',28,48,'D2',2),
('30000000-0000-0000-0000-000000000001','Biology',30,50,'D1',3),
('30000000-0000-0000-0000-000000000001','Chemistry',27,44,'D2',4),
('30000000-0000-0000-0000-000000000001','Physics',25,42,'D2',5),
('30000000-0000-0000-0000-000000000001','History',31,51,'D1',6),
('30000000-0000-0000-0000-000000000001','Kiswahili',29,47,'D2',7),
('30000000-0000-0000-0000-000000000001','CRE',33,55,'D1',8);

-- 6. Clinic (Nurse) -----------------------------------------------------
insert into clinic_visits (student_id, visited_at, complaint, notes, vitals, treatment, outcome, follow_up_note, recorded_by_name) values
('20000000-0000-0000-0000-000000000478','2026-07-09 10:24+03','Headache · mild fever',
 'Complaining of headache and mild fever. Paracetamol 500 mg administered. Advised rest until lunch. Returned to class after break.',
 '[{"label":"Temp","value":"37.9°C"},{"label":"BP","value":"108/68"},{"label":"Pulse","value":"88"},{"label":"Wt","value":"46 kg"}]',
 'Paracetamol 500 mg','followUp','Follow up 24 h','Nurse Alice N.'),
('20000000-0000-0000-0000-000000000478','2026-06-21 14:11+03','Minor cut · left knee',
 'Grazed knee during sports. Cleaned, dressed, and returned to games with plaster. No further action needed.',
 '[{"label":"Temp","value":"36.6°C"},{"label":"Wound","value":"Superficial"}]',
 null,'discharged',null,'Nurse Alice N.');

-- 7. Kitchen ------------------------------------------------------------
insert into menus (menu_date, breakfast, breakfast_side, lunch, lunch_side, supper, supper_side) values
('2026-07-06','Porridge · millet','Milk tea, bread','Posho & beans','Steamed cabbage','Rice & meat stew','Greens, fruit'),
('2026-07-07','Porridge · maize','Milk tea, bread','Matoke & groundnut','Boiled greens','Posho & beans','Fruit'),
('2026-07-08','Porridge · millet','Milk tea, bread','Posho & beans','Steamed cabbage','Rice & fish stew','Sukuma wiki'),
('2026-07-09','Porridge & bread','Millet, milk tea','Posho & beans','Steamed cabbage','Rice & fish stew','Sukuma wiki, fruit'),
('2026-07-10','Porridge · maize','Milk tea, bread','Matoke & beef stew','Boiled greens','Posho & silverfish','Fruit')
on conflict (menu_date) do nothing;

-- 8. Events & documents -------------------------------------------------
insert into events (title, starts_at, ends_at, venue, audience, category, highlight) values
('S4 Mock paper 1 · Mathematics','2026-07-10 08:30+03','2026-07-10 11:00+03','Main hall',null,'academic',false),
('Inter-house MDD final','2026-07-12 14:00+03',null,'Assembly hall',null,'coCurricular',false),
('Term 2 Visitation Day','2026-07-27 10:00+03','2026-07-27 14:00+03','School hall','Boarding parents','community',true),
('Report cards released','2026-07-28 08:00+03',null,'Available in app',null,'academic',false);

insert into documents (title, subtitle, url, student_id) values
('Term 2 fees breakdown','PDF · 340 KB','https://example.com/fees-t2-2026.pdf',null),
('School calendar 2026','PDF · 220 KB','https://example.com/calendar-2026.pdf',null),
('Parent handbook · 2026 ed.','PDF · 1.4 MB','https://example.com/handbook-2026.pdf',null),
('Safe release · pickup consent','Signed 03 Feb 2024','https://example.com/consent-00478.pdf','20000000-0000-0000-0000-000000000478');
