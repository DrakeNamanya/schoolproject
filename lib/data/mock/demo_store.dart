import 'package:flutter/foundation.dart';

import '../../models/academics.dart';
import '../../models/admin.dart';
import '../../models/clinic.dart';
import '../../models/fees.dart';
import '../../models/school.dart';
import '../../models/student.dart';

/// Single in-memory "database" shared by the mock Parent, Staff and Admin
/// repositories. Mirrors the Supabase tables so a write from one shell
/// (bursar posts a payment) is immediately visible in another (parent sees
/// the receipt) — exactly what the real backend will do via RLS + triggers.
///
/// Notifies listeners on every write so open screens refresh.
class DemoStore extends ChangeNotifier {
  DemoStore._() {
    _seed();
  }
  static final DemoStore instance = DemoStore._();

  // ---- identity ----------------------------------------------------------
  static const guardianId = 'demo-parent';
  static const teacherId = 'demo-teacher';

  // ---- tables ------------------------------------------------------------
  final List<Term> terms = [];
  final List<Student> students = [];
  final Map<String, Set<String>> studentGuardians = {}; // studentId -> guardianIds
  final Map<String, StudentSummary> summaries = {};
  final List<FeeLine> feeLines = []; // with studentId via _feeOwner
  final Map<String, String> _feeOwner = {}; // feeLineId -> studentId
  final List<PaymentRecord> payments = [];
  final List<PaymentChannel> channels = [];
  final List<ReportCard> reportCards = [];
  final List<ClinicVisit> clinicVisits = [];
  final Map<String, DayMenu> menus = {}; // yyyy-mm-dd -> menu
  final List<SchoolEvent> events = [];
  final List<SchoolDocument> documents = [];
  final List<Notice> notices = [];
  final List<Requisition> requisitions = [];
  final List<StockItem> stockItems = [];
  final List<MedicineStock> medicines = [];
  final List<StaffPresence> staffPresence = [];
  final List<AuditEntry> audit = [];

  Term get currentTerm => terms.firstWhere((t) => t.isCurrent);

  // ---- queries ------------------------------------------------------------
  List<Student> childrenOf(String guardianId) => students
      .where((s) => (studentGuardians[s.id] ?? const {}).contains(guardianId))
      .toList();

  List<FeeLine> feeLinesFor(String studentId) =>
      feeLines.where((l) => _feeOwner[l.id] == studentId).toList();

  List<PaymentRecord> paymentsFor(String studentId) =>
      payments.where((p) => p.studentId == studentId).toList()
        ..sort((a, b) => b.payment.paidAt.compareTo(a.payment.paidAt));

  int balanceFor(String studentId) {
    final inv = feeLinesFor(studentId).fold(0, (a, l) => a + l.amount);
    final paid = paymentsFor(studentId).fold(0, (a, p) => a + p.payment.amount);
    return inv - paid;
  }

  FeeStatus feeStatusFor(String studentId) {
    final b = balanceFor(studentId);
    if (b <= 0) return FeeStatus.cleared;
    final due = currentTerm.feesDueOn;
    if (due != null && DateTime.now().isAfter(due)) return FeeStatus.arrears;
    return FeeStatus.partial;
  }

  List<Notice> noticesFor(String guardianId) =>
      notices.where((n) => _noticeRecipient[n.id] == guardianId).toList()
        ..sort((a, b) => b.at.compareTo(a.at));
  final Map<String, String> _noticeRecipient = {};

  // ---- writes (what the admin shells call) --------------------------------

  void postPayment(String studentId, Payment p, {required String byName}) {
    payments.add(PaymentRecord(studentId, p));
    final s = students.firstWhere((x) => x.id == studentId);
    _notifyGuardians(
      studentId,
      NoticeKind.payment,
      'Receipt ${p.receiptNo}',
      '${p.method.label} · ${_fmtDt(p.paidAt)}',
      amount: p.amount,
    );
    _audit(byName, 'Bursar', 'Posted', 'payment UGX ${_n(p.amount)} for', s.admissionNo);
    notifyListeners();
  }

  void enrolStudent(Student s, String guardianId, {required String byName}) {
    students.add(s);
    (studentGuardians[s.id] ??= {}).add(guardianId);
    summaries[s.id] = StudentSummary(studentId: s.id, attendancePct: 0, clinicVisitsThisTerm: 0);
    // default invoice lines for the term
    _addFee(s.id, 'Tuition', 1200000);
    if (s.isBoarder) _addFee(s.id, 'Boarding', 450000);
    _addFee(s.id, 'Lunch programme', 180000);
    _audit(byName, 'Registrar', 'Enrolled', 'student', s.admissionNo);
    notifyListeners();
  }

  void recordClinicVisit(ClinicVisit v, {required String byName}) {
    clinicVisits.insert(0, v);
    final old = summaries[v.studentId];
    if (old != null) {
      summaries[v.studentId] = StudentSummary(
        studentId: old.studentId,
        attendancePct: old.attendancePct,
        position: old.position,
        classSize: old.classSize,
        clinicVisitsThisTerm: old.clinicVisitsThisTerm + 1,
      );
    }
    _notifyGuardians(
      v.studentId,
      NoticeKind.clinic,
      'Clinic: ${v.complaint}',
      '${v.recordedBy} · ${_fmtDt(v.visitedAt)}',
    );
    final s = students.firstWhere((x) => x.id == v.studentId);
    _audit(byName, 'Clinic', 'Added', 'clinic visit for', s.admissionNo);
    notifyListeners();
  }

  void publishReport(String reportId, {required String byName}) {
    final i = reportCards.indexWhere((r) => r.id == reportId);
    if (i < 0) return;
    final r = reportCards[i];
    reportCards[i] = ReportCard(
      id: r.id, studentId: r.studentId, termId: r.termId, termLabel: r.termLabel,
      className: r.className, position: r.position, classSize: r.classSize,
      results: r.results, classTeacherComment: r.classTeacherComment,
      classTeacherName: r.classTeacherName, headteacherComment: r.headteacherComment,
      status: ReportStatus.published, publishedAt: DateTime.now(), pdfUrl: r.pdfUrl,
    );
    _notifyGuardians(r.studentId, NoticeKind.academics, 'Report card released · ${r.termLabel}', 'Available in app');
    final s = students.firstWhere((x) => x.id == r.studentId);
    _audit(byName, 'DOS', 'Published', 'report card', s.admissionNo);
    notifyListeners();
  }

  void setMenu(DayMenu m, {required String byName}) {
    menus[_key(m.date)] = m;
    _audit(byName, 'Kitchen', 'Published', 'menu', _key(m.date));
    notifyListeners();
  }

  void addEvent(SchoolEvent e, {required String byName}) {
    events.add(e);
    events.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    for (final gid in studentGuardians.values.expand((s) => s).toSet()) {
      _addNotice(gid, null, NoticeKind.event, e.title, '${e.venue ?? e.audience ?? ''} · ${_fmtDt(e.startsAt)}');
    }
    _audit(byName, 'Registrar', 'Added', 'event', e.title);
    notifyListeners();
  }

  void setRequisitionStatus(String id, RequisitionStatus st, {required String byName}) {
    final i = requisitions.indexWhere((r) => r.id == id);
    if (i < 0) return;
    requisitions[i] = requisitions[i].withStatus(st);
    _audit(byName, 'Finance', st.name[0].toUpperCase() + st.name.substring(1), 'requisition', requisitions[i].ref);
    notifyListeners();
  }

  void markNoticeRead(String id) {
    final i = notices.indexWhere((n) => n.id == id);
    if (i >= 0 && !notices[i].read) {
      final n = notices[i];
      notices[i] = Notice(id: n.id, kind: n.kind, title: n.title, subtitle: n.subtitle, at: n.at, amount: n.amount, read: true, studentId: n.studentId);
      notifyListeners();
    }
  }

  // ---- internals ----------------------------------------------------------
  int _seq = 1000;
  String nextId(String prefix) => '$prefix-${_seq++}';
  String nextReceiptNo() => 'R-2026-${(892 + payments.length).toString().padLeft(4, '0')}';

  void _addFee(String studentId, String label, int amount) {
    final l = FeeLine(id: nextId('fl'), label: label, amount: amount);
    feeLines.add(l);
    _feeOwner[l.id] = studentId;
  }

  void _notifyGuardians(String studentId, NoticeKind k, String t, String st, {int? amount}) {
    for (final gid in studentGuardians[studentId] ?? const <String>{}) {
      _addNotice(gid, studentId, k, t, st, amount: amount);
    }
  }

  void _addNotice(String gid, String? studentId, NoticeKind k, String t, String st, {int? amount}) {
    final n = Notice(id: nextId('n'), kind: k, title: t, subtitle: st, at: DateTime.now(), amount: amount, studentId: studentId);
    notices.insert(0, n);
    _noticeRecipient[n.id] = gid;
  }

  void _audit(String who, String role, String action, String detail, String obj, {String level = 'i'}) {
    audit.insert(0, AuditEntry(at: DateTime.now(), who: who, role: role, action: action, detail: detail, object: obj, level: level));
  }

  static String _key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static String _fmtDt(DateTime d) => '${d.day.toString().padLeft(2, '0')} ${const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month - 1]}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  static String _n(int v) => v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  DayMenu? menuFor(DateTime d) => menus[_key(d)];

  // ---- seed -----------------------------------------------------------------
  void _seed() {
    final now = DateTime.now();
    terms.add(Term(id: 'term-2026-2', year: 2026, number: 2, startsOn: DateTime(2026, 5, 25), endsOn: DateTime(2026, 8, 21), feesDueOn: now.add(const Duration(days: 15)), isCurrent: true));

    void stu(String id, String adm, String fn, String sn, String cls, String house, bool boarder, String? dorm, String gid, {double att = 95, int? pos, int? size, int clinic = 0}) {
      students.add(Student(id: id, admissionNo: adm, firstName: fn, surname: sn, className: cls, house: house, isBoarder: boarder, dormitory: dorm, dateOfBirth: DateTime(2011, 3, 14), admittedOn: DateTime(2024, 2, 3)));
      (studentGuardians[id] ??= {}).add(gid);
      summaries[id] = StudentSummary(studentId: id, attendancePct: att, position: pos, classSize: size, clinicVisitsThisTerm: clinic);
    }

    stu('stu-00478', 'TGS/2024/00478', 'Aisha', 'Nakato', 'S2 East', 'Green', true, 'Kwagala dormitory, bed 14', guardianId, att: 96, pos: 12, size: 78, clinic: 2);
    stu('stu-00612', 'TGS/2025/00612', 'Grace', 'Nakato', 'S1 North', 'Blue', true, 'Kisubi dormitory, bed 3', guardianId, att: 99, pos: 4, size: 84);
    stu('stu-00512', 'TGS/2024/00512', 'Prossy', 'Akello', 'S2 West', 'Blue', true, 'Kwagala dormitory, bed 22', 'g-akello', att: 94, pos: 8, size: 76);
    stu('stu-00013', 'TGS/2021/00013', 'Winnie', 'Byaruhanga', 'S6 A', 'White', false, null, 'g-byaruhanga', att: 91, pos: 3, size: 84);
    stu('stu-00301', 'TGS/2023/00301', 'Esther', 'Kembabazi', 'S3 North', 'Red', true, 'Nsibirwa dormitory, bed 9', 'g-kembabazi', att: 97, pos: 15, size: 70);
    stu('stu-00521', 'TGS/2024/00521', 'Angel', 'Namuli', 'S2 South', 'Green', true, 'Kwagala dormitory, bed 31', 'g-namuli', att: 93, pos: 20, size: 74);
    stu('stu-00159', 'TGS/2022/00159', 'Mercy', 'Lamunu', 'S5 B', 'Red', true, 'Nsibirwa dormitory, bed 2', 'g-lamunu', att: 98, pos: 1, size: 98);
    stu('stu-00218', 'TGS/2023/00218', 'Patience', 'Ssenoga', 'S3 East', 'White', false, null, 'g-ssenoga', att: 92, pos: 11, size: 72);
    stu('stu-00087', 'TGS/2022/00087', 'Doreen', 'Ssekabira', 'S4 East', 'Blue', true, 'Kisubi dormitory, bed 18', 'g-ssekabira', att: 88, pos: 40, size: 74);
    stu('stu-00219', 'TGS/2023/00219', 'Kevin', 'Okello', 'S3 West', 'Red', true, 'Nsibirwa dormitory, bed 14', 'g-okello', att: 90, pos: 22, size: 70);

    // fees
    for (final s in students) {
      _addFee(s.id, 'Tuition', 1200000);
      if (s.isBoarder) _addFee(s.id, 'Boarding', 450000);
      _addFee(s.id, 'Lunch programme', 180000);
    }
    _addFee('stu-00478', 'Uniforms', 70000);

    void pay(String sid, String rn, int amt, PaymentMethod m, DateTime at, [String? ref]) =>
        payments.add(PaymentRecord(sid, Payment(id: nextId('p'), receiptNo: rn, amount: amt, method: m, paidAt: at, reference: ref)));

    pay('stu-00478', 'R-2026-0611', 1100000, PaymentMethod.bank, DateTime(2026, 5, 28, 10, 5), 'Stanbic · DEP 4471');
    pay('stu-00478', 'R-2026-0891', 350000, PaymentMethod.mtn, now.copyWith(hour: 9, minute: 12), 'MM 8813402771');
    pay('stu-00612', 'R-2026-0702', 1830000, PaymentMethod.bank, DateTime(2026, 6, 2, 11, 40));
    pay('stu-00512', 'R-2026-0640', 1830000, PaymentMethod.mtn, DateTime(2026, 5, 30, 8, 2));
    pay('stu-00013', 'R-2026-0655', 1290000, PaymentMethod.airtel, DateTime(2026, 6, 1, 15, 22));
    pay('stu-00301', 'R-2026-0660', 1830000, PaymentMethod.bank, DateTime(2026, 6, 1, 9, 0));
    pay('stu-00521', 'R-2026-0701', 1445000, PaymentMethod.mtn, DateTime(2026, 6, 4, 12, 30));
    pay('stu-00159', 'R-2026-0688', 1830000, PaymentMethod.bank, DateTime(2026, 6, 3, 10, 12));
    pay('stu-00218', 'R-2026-0720', 1380000, PaymentMethod.cash, DateTime(2026, 6, 6, 14, 0));
    pay('stu-00087', 'R-2026-0733', 490000, PaymentMethod.mtn, DateTime(2026, 6, 10, 9, 45));
    pay('stu-00219', 'R-2026-0750', 910000, PaymentMethod.airtel, DateTime(2026, 6, 12, 11, 15));

    channels.addAll(const [
      PaymentChannel(method: PaymentMethod.mtn, title: 'MTN Mobile Money', instruction: 'Dial *165# · school code 402108'),
      PaymentChannel(method: PaymentMethod.airtel, title: 'Airtel Money', instruction: 'Merchant code 402108'),
      PaymentChannel(method: PaymentMethod.bank, title: 'Stanbic Bank deposit', instruction: 'A/C 9030002187 · TGS Ltd'),
    ]);

    // report cards
    reportCards.add(ReportCard(
      id: 'rc-1', studentId: 'stu-00478', termId: 'term-2026-2', termLabel: 'Term 2 · 2026', className: 'S2 East',
      position: 12, classSize: 78, status: ReportStatus.published, publishedAt: DateTime(2026, 7, 9),
      classTeacherName: 'Ms. Kabuye R.',
      classTeacherComment: 'Aisha is a diligent and self-motivated girl. She should continue to work on the presentation of her Physics practicals. Well done this term.',
      results: const [
        SubjectResult(subject: 'Mathematics', catScore: 32, catOutOf: 40, examScore: 54, examOutOf: 60, grade: 'D1'),
        SubjectResult(subject: 'English', catScore: 28, catOutOf: 40, examScore: 48, examOutOf: 60, grade: 'D2'),
        SubjectResult(subject: 'Biology', catScore: 30, catOutOf: 40, examScore: 50, examOutOf: 60, grade: 'D1'),
        SubjectResult(subject: 'Chemistry', catScore: 27, catOutOf: 40, examScore: 44, examOutOf: 60, grade: 'D2'),
        SubjectResult(subject: 'Physics', catScore: 25, catOutOf: 40, examScore: 42, examOutOf: 60, grade: 'D2'),
        SubjectResult(subject: 'History', catScore: 31, catOutOf: 40, examScore: 51, examOutOf: 60, grade: 'D1'),
        SubjectResult(subject: 'Kiswahili', catScore: 29, catOutOf: 40, examScore: 47, examOutOf: 60, grade: 'D2'),
        SubjectResult(subject: 'CRE', catScore: 33, catOutOf: 40, examScore: 55, examOutOf: 60, grade: 'D1'),
      ],
    ));
    reportCards.add(ReportCard(
      id: 'rc-2', studentId: 'stu-00612', termId: 'term-2026-2', termLabel: 'Term 2 · 2026', className: 'S1 North',
      position: 4, classSize: 84, status: ReportStatus.review,
      classTeacherName: 'Mr. Ochieng L.',
      classTeacherComment: 'Grace has settled in very well and leads by example. Keep it up.',
      results: const [
        SubjectResult(subject: 'Mathematics', catScore: 36, catOutOf: 40, examScore: 56, examOutOf: 60, grade: 'D1'),
        SubjectResult(subject: 'English', catScore: 34, catOutOf: 40, examScore: 52, examOutOf: 60, grade: 'D1'),
        SubjectResult(subject: 'Biology', catScore: 31, catOutOf: 40, examScore: 49, examOutOf: 60, grade: 'D1'),
        SubjectResult(subject: 'Geography', catScore: 30, catOutOf: 40, examScore: 46, examOutOf: 60, grade: 'D2'),
        SubjectResult(subject: 'Kiswahili', catScore: 33, catOutOf: 40, examScore: 50, examOutOf: 60, grade: 'D1'),
      ],
    ));
    reportCards.add(ReportCard(
      id: 'rc-3', studentId: 'stu-00512', termId: 'term-2026-2', termLabel: 'Term 2 · 2026', className: 'S2 West',
      position: 8, classSize: 76, status: ReportStatus.review, classTeacherName: 'Ms. Nabbosa J.',
      classTeacherComment: 'Prossy participates actively in class. More practice in Mathematics recommended.',
      results: const [
        SubjectResult(subject: 'Mathematics', catScore: 24, catOutOf: 40, examScore: 40, examOutOf: 60, grade: 'C3'),
        SubjectResult(subject: 'English', catScore: 33, catOutOf: 40, examScore: 51, examOutOf: 60, grade: 'D1'),
        SubjectResult(subject: 'Biology', catScore: 29, catOutOf: 40, examScore: 47, examOutOf: 60, grade: 'D2'),
      ],
    ));

    // clinic
    clinicVisits.addAll([
      ClinicVisit(id: 'cv-2', studentId: 'stu-00478', visitedAt: now.copyWith(hour: 10, minute: 24), complaint: 'Headache · mild fever',
        notes: 'Complaining of headache and mild fever. Paracetamol 500 mg administered. Advised rest until lunch. Returned to class after break.',
        treatment: 'Paracetamol 500 mg', vitals: const [Vital('Temp', '37.9°C'), Vital('BP', '108/68'), Vital('Pulse', '88'), Vital('Wt', '46 kg')],
        outcome: VisitOutcome.followUp, followUpNote: 'Follow up 24 h', recordedBy: 'Nurse Alice N.'),
      ClinicVisit(id: 'cv-3', studentId: 'stu-00512', visitedAt: now.copyWith(hour: 11, minute: 2), complaint: 'Mild fever · 38.1°C',
        notes: 'Under observation in the sanatorium. Fluids given.', vitals: const [Vital('Temp', '38.1°C'), Vital('Pulse', '92')],
        outcome: VisitOutcome.observing, recordedBy: 'Nurse Alice N.'),
      ClinicVisit(id: 'cv-4', studentId: 'stu-00301', visitedAt: now.copyWith(hour: 11, minute: 44), complaint: 'Minor scrape',
        notes: 'Dressed · returned to class.', vitals: const [], outcome: VisitOutcome.discharged, recordedBy: 'Nurse Alice N.'),
      ClinicVisit(id: 'cv-5', studentId: 'stu-00013', visitedAt: now.copyWith(hour: 13, minute: 5), complaint: 'Ophthalmology follow-up',
        notes: 'Referred to Uganda Medical Centre with parent consent.', vitals: const [], outcome: VisitOutcome.referred, referralFacility: 'Uganda Medical Centre', recordedBy: 'Nurse Alice N.'),
      ClinicVisit(id: 'cv-1', studentId: 'stu-00478', visitedAt: DateTime(2026, 6, 21, 14, 11), complaint: 'Minor cut · left knee',
        notes: 'Grazed knee during sports. Cleaned, dressed, and returned to games with plaster. No further action needed.',
        vitals: const [Vital('Temp', '36.6°C'), Vital('Wound', 'Superficial')], outcome: VisitOutcome.discharged, recordedBy: 'Nurse Alice N.'),
    ]);

    medicines.addAll(const [
      MedicineStock(id: 'md-1', name: 'Paracetamol 500 mg', batch: 'BATCH-2026-041', expiry: '07/2027', qty: 48, unit: 'tab', reorderAt: 200),
      MedicineStock(id: 'md-2', name: 'ORS sachets', batch: 'BATCH-2026-018', expiry: '12/2027', qty: 9, unit: 'pk', reorderAt: 40),
      MedicineStock(id: 'md-3', name: 'Amoxicillin 250 mg', batch: 'BATCH-2026-033', expiry: '03/2028', qty: 120, unit: 'cap', reorderAt: 100),
      MedicineStock(id: 'md-4', name: 'Cetirizine 10 mg', batch: 'BATCH-2026-021', expiry: '06/2028', qty: 78, unit: 'tab', reorderAt: 40),
      MedicineStock(id: 'md-5', name: 'Sanitary pads (regular)', batch: 'Welfare programme', expiry: '—', qty: 124, unit: 'pk', reorderAt: 60),
      MedicineStock(id: 'md-6', name: 'Bandage · elastic', batch: 'BATCH-2026-009', expiry: '11/2029', qty: 18, unit: 'rolls', reorderAt: 10),
    ]);

    // menus (this week)
    final mon = now.subtract(Duration(days: now.weekday - 1));
    const wk = [
      ('Porridge · millet', 'Milk tea, bread', 'Posho & beans', 'Steamed cabbage', 'Rice & meat stew', 'Greens, fruit'),
      ('Porridge · maize', 'Milk tea, bread', 'Matoke & groundnut', 'Boiled greens', 'Posho & beans', 'Fruit'),
      ('Porridge · millet', 'Milk tea, bread', 'Posho & beans', 'Steamed cabbage', 'Rice & fish stew', 'Sukuma wiki'),
      ('Porridge · maize', 'Milk tea, bread', 'Matoke & beef stew', 'Boiled greens', 'Posho & silverfish', 'Fruit'),
      ('Porridge · millet', 'Milk tea, bread', 'Rice & bean stew', 'Cabbage salad', 'Matoke & meat', 'Watermelon'),
      ('Bread & tea', 'Boiled eggs', 'Posho & beans', 'Greens', 'Rice & beans', 'Fruit'),
      ('Porridge · millet', 'Bread', 'Matoke & groundnut', 'Greens', 'Posho & beef', 'Fruit'),
    ];
    for (var i = 0; i < 7; i++) {
      final d = DateTime(mon.year, mon.month, mon.day + i);
      menus[_key(d)] = DayMenu(date: d, breakfast: Meal(wk[i].$1, wk[i].$2), lunch: Meal(wk[i].$3, wk[i].$4), supper: Meal(wk[i].$5, wk[i].$6));
    }

    events.addAll([
      SchoolEvent(id: 'e1', title: 'S4 Mock paper 1 · Mathematics', startsAt: now.add(const Duration(days: 1)).copyWith(hour: 8, minute: 30), endsAt: now.add(const Duration(days: 1)).copyWith(hour: 11), venue: 'Main hall', category: EventCategory.academic),
      SchoolEvent(id: 'e2', title: 'Inter-house MDD final', startsAt: now.add(const Duration(days: 3)).copyWith(hour: 14), venue: 'Assembly hall', category: EventCategory.coCurricular),
      SchoolEvent(id: 'e3', title: 'Term 2 Visitation Day', startsAt: now.add(const Duration(days: 18)).copyWith(hour: 10), endsAt: now.add(const Duration(days: 18)).copyWith(hour: 14), audience: 'Boarding parents', category: EventCategory.community, highlight: true),
      SchoolEvent(id: 'e4', title: 'Report cards released', startsAt: now.add(const Duration(days: 19)).copyWith(hour: 8), venue: 'Available in app', category: EventCategory.academic),
      SchoolEvent(id: 'e5', title: 'Fees deadline', startsAt: now.add(const Duration(days: 15)).copyWith(hour: 17), venue: 'Bursar', category: EventCategory.academic),
      SchoolEvent(id: 'e6', title: 'Career day', startsAt: now.add(const Duration(days: 13)).copyWith(hour: 9), venue: 'Main hall', category: EventCategory.coCurricular),
    ]);

    documents.addAll([
      const SchoolDocument(id: 'd1', title: 'Term 2 fees breakdown', subtitle: 'PDF · 340 KB', url: ''),
      const SchoolDocument(id: 'd2', title: 'School calendar 2026', subtitle: 'PDF · 220 KB', url: ''),
      const SchoolDocument(id: 'd3', title: 'Parent handbook · 2026 ed.', subtitle: 'PDF · 1.4 MB', url: ''),
      const SchoolDocument(id: 'd4', title: 'Safe release · pickup consent', subtitle: 'Signed 03 Feb 2024', url: '', studentId: 'stu-00478'),
    ]);

    _addNotice(guardianId, 'stu-00478', NoticeKind.payment, 'Receipt R-2026-0891', 'MTN Mobile Money · ${_fmtDt(now.copyWith(hour: 9, minute: 12))}', amount: 350000);
    _addNotice(guardianId, 'stu-00478', NoticeKind.clinic, 'Clinic: headache, paracetamol given', 'Nurse Alice N. · ${_fmtDt(now.copyWith(hour: 10, minute: 24))}');
    _addNotice(guardianId, null, NoticeKind.event, 'Visitation Day · ${events[2].startsAt.day} ${_fmtDt(events[2].startsAt).split(' ')[1].replaceAll(',', '')}', 'School hall · 10:00–14:00');

    requisitions.addAll([
      Requisition(id: 'rq-1', ref: 'REQ-0347', title: 'Lab reagents · Chemistry', dept: 'Academics', requester: 'L. Ochieng (DOS)', date: now.subtract(const Duration(days: 1)), amount: 1240000, lines: 3, status: RequisitionStatus.bursar),
      Requisition(id: 'rq-2', ref: 'REQ-0346', title: 'Kitchen · 200 kg maize flour', dept: 'Kitchen', requester: 'M. Nakku (Cook)', date: now.subtract(const Duration(days: 1)), amount: 480000, lines: 1, status: RequisitionStatus.approved),
      Requisition(id: 'rq-3', ref: 'REQ-0345', title: 'Exercise books · 12 dozen', dept: 'Stores', requester: 'Stores officer', date: now.subtract(const Duration(days: 2)), amount: 216000, lines: 2, status: RequisitionStatus.approved),
      Requisition(id: 'rq-4', ref: 'REQ-0343', title: 'Sports uniform batch', dept: 'MDD', requester: 'MDD dept', date: now.subtract(const Duration(days: 2)), amount: 2860000, lines: 4, status: RequisitionStatus.rejected),
      Requisition(id: 'rq-5', ref: 'REQ-0342', title: 'Diesel · school van', dept: 'Transport', requester: 'Mr. Walusansa P.', date: now.subtract(const Duration(days: 3)), amount: 320000, lines: 1, status: RequisitionStatus.director),
      Requisition(id: 'rq-6', ref: 'REQ-0341', title: 'Lab consumables · Physics', dept: 'Academics', requester: 'B. Ssekandi', date: now.subtract(const Duration(days: 4)), amount: 480000, lines: 2, status: RequisitionStatus.approved),
    ]);

    stockItems.addAll(const [
      StockItem(id: 'sk-1', sku: 'STA-EB-096', name: 'Exercise books · 96 pg', category: 'Stationery', onHand: 12, reorderAt: 20, unit: 'doz', lastIssued: '08 Jul · S3E'),
      StockItem(id: 'sk-2', sku: 'STA-CHK-WHT', name: 'Chalk · white', category: 'Stationery', onHand: 84, reorderAt: 40, unit: 'box', lastIssued: '05 Jul · Blk A'),
      StockItem(id: 'sk-3', sku: 'UNI-BLZ-S3', name: 'Uniform · blouse S3', category: 'Uniforms', onHand: 28, reorderAt: 25, unit: 'pc', lastIssued: '03 Jul · Kwagala'),
      StockItem(id: 'sk-4', sku: 'CLN-TP-ROLL', name: 'Toilet paper · rolls', category: 'Cleaning', onHand: 42, reorderAt: 80, unit: 'roll', lastIssued: '09 Jul · Sanitation'),
      StockItem(id: 'sk-5', sku: 'CLN-DET-800', name: 'Detergent · bar 800g', category: 'Cleaning', onHand: 64, reorderAt: 50, unit: 'pc', lastIssued: '07 Jul · Laundry'),
      StockItem(id: 'sk-6', sku: 'KIT-MAZ-50K', name: 'Maize flour · sacks 50 kg', category: 'Kitchen', onHand: 8, reorderAt: 6, unit: 'sk', lastIssued: '09 Jul · Kitchen'),
      StockItem(id: 'sk-7', sku: 'KIT-CHR-SAC', name: 'Charcoal · sacks', category: 'Kitchen', onHand: 4, reorderAt: 10, unit: 'sk', lastIssued: '09 Jul · Kitchen'),
      StockItem(id: 'sk-8', sku: 'KIT-RCE-25K', name: 'Rice · 25 kg', category: 'Kitchen', onHand: 7, reorderAt: 5, unit: 'sk', lastIssued: '08 Jul · Kitchen'),
    ]);

    staffPresence.addAll([
      StaffPresence(name: 'Mr. Ssekandi B.', role: 'Physics · Day duty', status: PresenceStatus.inside, time: '07:38', detail: 'Auto-in · ±6 m', x: .26, y: .36),
      StaffPresence(name: 'Ms. Nakku M.', role: 'Head cook', status: PresenceStatus.inside, time: '05:52', detail: 'Auto-in · ±8 m', x: .32, y: .42),
      StaffPresence(name: 'Nurse Alice N.', role: 'Clinic', status: PresenceStatus.inside, time: '07:14', detail: 'Auto-in · ±5 m', x: .24, y: .48),
      StaffPresence(name: 'Ms. Nabbosa J.', role: 'English · S4', status: PresenceStatus.outside, time: '420 m', detail: 'Off · escalated', x: .76, y: .24),
      StaffPresence(name: 'Mr. Ochieng L.', role: 'Chemistry · DOS', status: PresenceStatus.inside, time: '07:22', detail: 'Auto-in · ±7 m', x: .30, y: .52),
      StaffPresence(name: 'Ms. Kabuye R.', role: 'Mathematics · S6', status: PresenceStatus.inside, time: '07:41', detail: 'Auto-in · ±6 m', x: .38, y: .38),
      StaffPresence(name: 'Mr. Walusansa P.', role: 'Transport · Off duty', status: PresenceStatus.offDuty, time: '—', detail: 'Roster-off', x: 0, y: 0),
      StaffPresence(name: 'Ms. Nakato F.', role: 'Matron · Kwagala', status: PresenceStatus.inside, time: '06:44', detail: 'Auto-in · ±5 m', x: .36, y: .46),
      StaffPresence(name: 'Mr. Kato D.', role: 'Geography · S3', status: PresenceStatus.inside, time: '07:52', detail: 'Auto-in · ±9 m · late 7 min', x: .28, y: .58),
      StaffPresence(name: 'Ms. Apio C.', role: 'Bursar office', status: PresenceStatus.inside, time: '07:30', detail: 'Auto-in · ±5 m', x: .34, y: .56),
    ]);

    audit.addAll([
      AuditEntry(at: now.copyWith(hour: 13, minute: 58), who: 'J. Nsubuga', role: 'Bursar', action: 'Posted', detail: 'payment UGX 350,000 for', object: 'TGS/2024/00478'),
      AuditEntry(at: now.copyWith(hour: 13, minute: 22), who: 'L. Ochieng', role: 'DOS', action: 'Approved', detail: 'requisition', object: 'REQ-0346'),
      AuditEntry(at: now.copyWith(hour: 12, minute: 11), who: 'Nurse Alice N.', role: 'Clinic', action: 'Added', detail: 'clinic visit for', object: 'TGS/2022/00087'),
      AuditEntry(at: now.copyWith(hour: 11, minute: 42), who: 'Ms. Kabuye R.', role: 'Teacher', action: 'Edited', detail: 'Physics marks · CAT 2', object: 'S3 East'),
      AuditEntry(at: now.copyWith(hour: 9, minute: 45), who: 'SYSTEM', role: 'Geofence', action: 'Flagged', detail: 'off-campus during class hours', object: 'Ms. Nabbosa J.', level: 'd'),
      AuditEntry(at: now.copyWith(hour: 9, minute: 12), who: 'Ms. Nabbosa J.', role: 'Teacher', action: 'Failed', detail: 'attempt to edit locked marks', object: 'S4 East · Eng', level: 'w'),
      AuditEntry(at: now.copyWith(hour: 7, minute: 41), who: 'Ms. Kabuye R.', role: 'Teacher', action: 'Auto check-in', detail: 'via geofence', object: '±6 m · 07:41'),
      AuditEntry(at: now.copyWith(hour: 7, minute: 38), who: 'Mr. Ssekandi B.', role: 'Teacher', action: 'Auto check-in', detail: 'via geofence', object: '±6 m · 07:38'),
      AuditEntry(at: now.subtract(const Duration(days: 1)).copyWith(hour: 22, minute: 58), who: 'SYSTEM', role: 'Backup', action: 'Completed', detail: 'full DB backup', object: 'tgs-prod-2026-07-08'),
      AuditEntry(at: now.subtract(const Duration(days: 1)).copyWith(hour: 21, minute: 14), who: 'Admin (root)', role: 'IT', action: 'Rotated', detail: 'API key', object: 'fcm-server-key', level: 'w'),
    ]);
  }
}

/// payments table row: (student_id, payment)
class PaymentRecord {
  final String studentId;
  final Payment payment;
  const PaymentRecord(this.studentId, this.payment);
}
