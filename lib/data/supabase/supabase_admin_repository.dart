import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/academics.dart';
import '../../models/admin.dart';
import '../../models/clinic.dart';
import '../../models/fees.dart';
import '../../models/school.dart';
import '../../models/student.dart';
import '../admin_repository.dart';

/// Admin console against Supabase. Views/RPCs: 0003_admin.sql + 0004.
/// The bursar / nurse / registrar type the STUDENT NUMBER; we resolve it via
/// `student_by_no` / `post_payment` RPCs so the number is the working key.
class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository(this._db);
  final SupabaseClient _db;
  Map<String, dynamic> _m(dynamic r) => Map<String, dynamic>.from(r as Map);

  // cache of v_students_admin for cheap balance/status lookups
  List<Map<String, dynamic>>? _studentsCache;
  Future<List<Map<String, dynamic>>> _studentsAdmin({bool refresh = false}) async {
    if (_studentsCache == null || refresh) {
      final rows = await _db.from('v_students_admin').select().order('class_name').order('surname');
      _studentsCache = (rows as List).map(_m).toList();
    }
    return _studentsCache!;
  }

  Term? _term;
  Future<Term> _currentTerm() async => _term ??= Term.fromMap(await _db.from('terms').select().eq('is_current', true).limit(1).single());

  // ---- Dashboard ---------------------------------------------------------
  @override
  Future<FinanceKpis> financeKpis() async {
    final k = await _db.from('v_finance_kpis').select().single();
    final pays = await _db.from('payments').select('amount, method');
    var mtn = 0, airtel = 0, bank = 0;
    for (final p in pays as List) {
      final a = (p['amount'] as num).toInt();
      switch (p['method']) {
        case 'mtn': mtn += a;
        case 'airtel': airtel += a;
        default: bank += a;
      }
    }
    final tot = (mtn + airtel + bank).clamp(1, 1 << 62);
    return FinanceKpis(
      invoiced: ((k['invoiced'] as num?) ?? 0).toInt(),
      collected: ((k['collected'] as num?) ?? 0).toInt(),
      today: ((k['today'] as num?) ?? 0).toInt(),
      arrearsCount: ((k['arrears_count'] as num?) ?? 0).toInt(),
      partialCount: ((k['partial_count'] as num?) ?? 0).toInt(),
      clearedCount: ((k['cleared_count'] as num?) ?? 0).toInt(),
      mtnShare: mtn * 100 ~/ tot,
      airtelShare: airtel * 100 ~/ tot,
      bankShare: bank * 100 ~/ tot,
    );
  }

  @override
  Future<List<StaffPresence>> staffPresence() async {
    final rows = await _db.from('v_staff_presence').select().order('full_name');
    var i = 0;
    return (rows as List).map((r) {
      final m = _m(r);
      final st = switch (m['status']) { 'inside' => PresenceStatus.inside, 'outside' => PresenceStatus.outside, _ => PresenceStatus.offDuty };
      final at = m['last_at'] == null ? null : DateTime.parse(m['last_at'] as String).toLocal();
      final dist = (m['distance_m'] as num?)?.toDouble();
      // deterministic scatter inside/outside the fence for the map
      final ang = (i++ * 2.399);
      final rad = st == PresenceStatus.outside ? .42 : .06 + (i % 5) * .045;
      return StaffPresence(
        name: m['full_name'] as String,
        role: [m['department'], m['job_title']].whereType<String>().join(' · '),
        status: st,
        time: st == PresenceStatus.outside ? '${dist?.round() ?? 0} m' : at == null ? '—' : '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}',
        detail: st == PresenceStatus.offDuty ? 'Roster-off' : st == PresenceStatus.outside ? 'Off · escalated' : 'Auto-in · ±${(m['accuracy_m'] as num?)?.round() ?? 6} m',
        x: .32 + rad * _cos(ang),
        y: .48 + rad * _sin(ang) * 1.3,
      );
    }).toList();
  }

  static double _cos(double a) => _cosT(a);
  static double _sin(double a) => _cosT(a - 1.5707963);
  static double _cosT(double a) {
    // tiny Taylor cos to avoid importing dart:math in a data file
    a = a % 6.2831853;
    if (a > 3.1415926) a -= 6.2831853;
    final a2 = a * a;
    return 1 - a2 / 2 + a2 * a2 / 24 - a2 * a2 * a2 / 720 + a2 * a2 * a2 * a2 / 40320;
  }

  @override
  Future<List<Requisition>> requisitions() async {
    final rows = await _db.from('requisitions').select().order('created_at', ascending: false);
    return (rows as List).map((r) {
      final m = _m(r);
      return Requisition(
        id: m['id'] as String,
        ref: m['ref'] as String,
        title: m['title'] as String,
        dept: m['department'] as String,
        requester: (m['requester_name'] as String?) ?? '',
        date: DateTime.parse(m['created_at'] as String).toLocal(),
        amount: (m['amount'] as num).toInt(),
        lines: 1,
        status: RequisitionStatus.values.firstWhere((s) => s.name == m['status'], orElse: () => RequisitionStatus.bursar),
      );
    }).toList();
  }

  @override
  Future<List<AuditEntry>> auditLog({int limit = 50}) async {
    final rows = await _db.from('audit_log').select().order('at', ascending: false).limit(limit);
    return (rows as List).map((r) {
      final m = _m(r);
      final after = m['after'] as Map?;
      final ent = m['entity'] as String;
      final obj = after?['receipt_no'] ?? after?['ref'] ?? after?['admission_no'] ?? after?['complaint'] ?? (m['entity_id'] as String? ?? '').toString();
      return AuditEntry(
        at: DateTime.parse(m['at'] as String).toLocal(),
        who: (m['actor_name'] as String?) ?? 'SYSTEM',
        role: ent == 'payments' || ent == 'fee_lines' ? 'Bursar' : ent == 'clinic_visits' ? 'Clinic' : ent == 'marks' ? 'Teacher' : ent == 'report_cards' ? 'DOS' : ent == 'requisitions' ? 'Procurement' : ent,
        action: switch (m['action']) { 'INSERT' => 'Added', 'UPDATE' => 'Edited', 'DELETE' => 'Deleted', _ => m['action'] as String },
        detail: ent.replaceAll('_', ' '),
        object: obj.toString(),
        level: (m['severity'] as String?) == 'alert' ? 'd' : (m['severity'] as String?) == 'warn' ? 'w' : 'i',
      );
    }).toList();
  }

  // ---- Students ----------------------------------------------------------
  @override
  Future<List<Student>> students() async => (await _studentsAdmin(refresh: true)).map(Student.fromMap).toList();

  @override
  Future<StudentSummary> summary(String id) async {
    final m = (await _studentsAdmin()).firstWhere((s) => s['id'] == id, orElse: () => {});
    return StudentSummary(
      studentId: id,
      attendancePct: ((m['attendance_pct'] as num?) ?? 0).toDouble(),
      position: (m['position'] as num?)?.toInt(),
      classSize: (m['class_size'] as num?)?.toInt(),
      clinicVisitsThisTerm: ((m['clinic_visits'] as num?) ?? 0).toInt(),
    );
  }

  @override
  Future<int> balance(String id) async {
    final m = (await _studentsAdmin()).firstWhere((s) => s['id'] == id, orElse: () => {});
    return ((m['invoiced'] as num?) ?? 0).toInt() - ((m['paid'] as num?) ?? 0).toInt();
  }

  @override
  Future<FeeStatus> feeStatus(String id) async {
    final b = await balance(id);
    if (b <= 0) return FeeStatus.cleared;
    final t = await _currentTerm();
    return t.feesDueOn != null && DateTime.now().isAfter(t.feesDueOn!) ? FeeStatus.arrears : FeeStatus.partial;
  }

  @override
  Future<void> enrolStudent(Student s, {required String guardianName, required String guardianPhone, required String byName}) async {
    final cls = await _db.from('classes').select('id').eq('name', s.className).maybeSingle();
    await _db.rpc('enrol_student', params: {
      'p_first': s.firstName,
      'p_surname': s.surname,
      'p_class_id': cls?['id'],
      'p_house': s.house,
      'p_boarder': s.isBoarder,
      'p_guardian_name': guardianName,
      'p_guardian_phone': guardianPhone,
      'p_pin': '123456',
    });
    _studentsCache = null;
  }

  // ---- Finance -----------------------------------------------------------------
  @override
  Future<List<PaymentRecord>> recentPayments({int limit = 50}) async {
    final rows = await _db.from('v_payments_admin').select().order('paid_at', ascending: false).limit(limit);
    return (rows as List).map((r) => PaymentRecord(r['student_id'] as String, Payment.fromMap(_m(r)))).toList();
  }

  @override
  Future<Payment> postPayment(String studentId, int amount, PaymentMethod method, String? reference, {required String byName}) async {
    final s = (await _studentsAdmin()).firstWhere((x) => x['id'] == studentId);
    final row = await _db.rpc('post_payment', params: {
      'p_student_no': s['admission_no'],
      'p_amount': amount,
      'p_method': method.name,
      'p_reference': reference,
    });
    _studentsCache = null;
    return Payment.fromMap(_m(row));
  }

  // ---- Academics ---------------------------------------------------------------
  @override
  Future<List<ReportCard>> reportCards() async {
    final rcs = await _db.from('v_report_cards_admin').select().order('status').order('class_name');
    final ids = (rcs as List).map((r) => r['id'] as String).toList();
    final results = ids.isEmpty ? <dynamic>[] : await _db.from('report_card_results').select().inFilter('report_card_id', ids).order('sort_order');
    final byRc = <String, List<SubjectResult>>{};
    for (final r in results) {
      (byRc[r['report_card_id'] as String] ??= []).add(SubjectResult.fromMap(_m(r)));
    }
    return rcs.map((r) => ReportCard.fromMap(_m(r), results: byRc[r['id']] ?? const [])).toList();
  }

  @override
  Future<void> publishReport(String reportId, {required String byName}) => _db.from('report_cards').update({
        'status': 'published',
        'published_at': DateTime.now().toUtc().toIso8601String(),
        'published_by': _db.auth.currentUser?.id,
      }).eq('id', reportId);

  // ---- Clinic ------------------------------------------------------------------
  @override
  Future<List<ClinicVisit>> clinicVisitsToday() async {
    final n = DateTime.now();
    final rows = await _db.from('clinic_visits').select().gte('visited_at', DateTime(n.year, n.month, n.day).toUtc().toIso8601String()).order('visited_at', ascending: false);
    return (rows as List).map((r) => ClinicVisit.fromMap(_m(r))).toList();
  }

  @override
  Future<List<ClinicVisit>> referralsThisTerm() async {
    final rows = await _db.from('clinic_visits').select().eq('outcome', 'referred').order('visited_at', ascending: false);
    return (rows as List).map((r) => ClinicVisit.fromMap(_m(r))).toList();
  }

  @override
  Future<List<MedicineStock>> medicines() async {
    final rows = await _db.from('medicine_stock').select().order('name');
    return (rows as List).map((r) {
      final m = _m(r);
      return MedicineStock(
        id: m['id'] as String,
        name: m['name'] as String,
        batch: (m['batch'] as String?) ?? '',
        expiry: m['expires_on'] == null ? '—' : (m['expires_on'] as String).substring(0, 7).split('-').reversed.join('/'),
        qty: (m['qty'] as num).toInt(),
        unit: m['unit'] as String,
        reorderAt: (m['reorder_at'] as num).toInt(),
      );
    }).toList();
  }

  @override
  Future<void> recordVisit(ClinicVisit v, {required String byName}) => _db.from('clinic_visits').insert({
        'student_id': v.studentId,
        'visited_at': v.visitedAt.toUtc().toIso8601String(),
        'complaint': v.complaint,
        'notes': v.notes,
        'vitals': v.vitals.map((x) => {'label': x.label, 'value': x.value}).toList(),
        'treatment': v.treatment,
        'outcome': v.outcome.name,
        'follow_up_note': v.followUpNote,
        'referral_facility': v.referralFacility,
        'recorded_by': _db.auth.currentUser?.id,
        'recorded_by_name': v.recordedBy,
      });

  // ---- Kitchen -------------------------------------------------------------------
  @override
  Future<List<DayMenu?>> weekMenu(DateTime monday) async {
    final from = monday.toIso8601String().substring(0, 10);
    final to = monday.add(const Duration(days: 6)).toIso8601String().substring(0, 10);
    final rows = await _db.from('menus').select().gte('menu_date', from).lte('menu_date', to);
    final by = {for (final r in rows as List) (r['menu_date'] as String).substring(0, 10): DayMenu.fromMap(_m(r))};
    return List.generate(7, (i) => by[monday.add(Duration(days: i)).toIso8601String().substring(0, 10)]);
  }

  @override
  Future<void> setMenu(DayMenu m, {required String byName}) => _db.from('menus').upsert({
        'menu_date': m.date.toIso8601String().substring(0, 10),
        'breakfast': m.breakfast.main, 'breakfast_side': m.breakfast.side,
        'lunch': m.lunch.main, 'lunch_side': m.lunch.side,
        'supper': m.supper.main, 'supper_side': m.supper.side,
        'published_by': _db.auth.currentUser?.id,
        'published_at': DateTime.now().toUtc().toIso8601String(),
      });

  // ---- Events ----------------------------------------------------------------------
  @override
  Future<List<SchoolEvent>> events() async {
    final rows = await _db.from('events').select().order('starts_at');
    return (rows as List).map((r) => SchoolEvent.fromMap(_m(r))).toList();
  }

  @override
  Future<void> addEvent(SchoolEvent e, {required String byName}) => _db.from('events').insert({
        'title': e.title,
        'starts_at': e.startsAt.toUtc().toIso8601String(),
        'ends_at': e.endsAt?.toUtc().toIso8601String(),
        'venue': e.venue,
        'audience': e.audience,
        'category': e.category.name,
        'highlight': e.highlight,
        'created_by': _db.auth.currentUser?.id,
      });

  // ---- Procurement / Stores ---------------------------------------------------------
  @override
  Future<void> setRequisitionStatus(String id, RequisitionStatus s, {required String byName}) {
    final uid = _db.auth.currentUser?.id;
    final now = DateTime.now().toUtc().toIso8601String();
    final patch = <String, dynamic>{'status': s.name};
    if (s == RequisitionStatus.director) patch.addAll({'bursar_by': uid, 'bursar_at': now});
    if (s == RequisitionStatus.approved) patch.addAll({'director_by': uid, 'director_at': now});
    return _db.from('requisitions').update(patch).eq('id', id);
  }

  @override
  Future<List<StockItem>> stock() async {
    final rows = await _db.from('stock_items').select().order('category').order('name');
    return (rows as List).map((r) {
      final m = _m(r);
      return StockItem(
        id: m['id'] as String,
        sku: m['sku'] as String,
        name: m['name'] as String,
        category: m['category'] as String,
        onHand: (m['on_hand'] as num).toInt(),
        reorderAt: (m['reorder_at'] as num).toInt(),
        unit: m['unit'] as String,
        lastIssued: '—',
      );
    }).toList();
  }
}
