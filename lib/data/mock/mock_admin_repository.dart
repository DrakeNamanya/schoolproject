import '../../models/academics.dart';
import '../../models/admin.dart';
import '../../models/clinic.dart';
import '../../models/fees.dart';
import '../../models/school.dart';
import '../../models/student.dart';
import '../admin_repository.dart';
import 'demo_store.dart';

class MockAdminRepository implements AdminRepository {
  final DemoStore _s = DemoStore.instance;
  Future<T> _d<T>(T v) => Future.delayed(const Duration(milliseconds: 120), () => v);

  @override
  Future<FinanceKpis> financeKpis() {
    var invoiced = 0, collected = 0, today = 0, arrears = 0, partial = 0, cleared = 0;
    var mtn = 0, airtel = 0, bank = 0;
    final now = DateTime.now();
    for (final s in _s.students) {
      invoiced += _s.feeLinesFor(s.id).fold(0, (a, l) => a + l.amount);
      switch (_s.feeStatusFor(s.id)) {
        case FeeStatus.arrears: arrears++;
        case FeeStatus.partial: partial++;
        case FeeStatus.cleared: cleared++;
      }
    }
    for (final p in _s.payments) {
      collected += p.payment.amount;
      if (p.payment.paidAt.year == now.year && p.payment.paidAt.month == now.month && p.payment.paidAt.day == now.day) today += p.payment.amount;
      switch (p.payment.method) {
        case PaymentMethod.mtn: mtn += p.payment.amount;
        case PaymentMethod.airtel: airtel += p.payment.amount;
        default: bank += p.payment.amount;
      }
    }
    final tot = (mtn + airtel + bank).clamp(1, 1 << 62);
    return _d(FinanceKpis(
      invoiced: invoiced, collected: collected, today: today,
      arrearsCount: arrears, partialCount: partial, clearedCount: cleared,
      mtnShare: mtn * 100 ~/ tot, airtelShare: airtel * 100 ~/ tot, bankShare: bank * 100 ~/ tot,
    ));
  }

  @override
  Future<List<StaffPresence>> staffPresence() => _d(_s.staffPresence);
  @override
  Future<List<Requisition>> requisitions() => _d(List.of(_s.requisitions));
  @override
  Future<List<AuditEntry>> auditLog({int limit = 50}) => _d(_s.audit.take(limit).toList());

  @override
  Future<List<Student>> students() => _d(List.of(_s.students));
  @override
  Future<StudentSummary> summary(String id) => _d(_s.summaries[id] ?? StudentSummary(studentId: id, attendancePct: 0, clinicVisitsThisTerm: 0));
  @override
  Future<FeeStatus> feeStatus(String id) => _d(_s.feeStatusFor(id));
  @override
  Future<int> balance(String id) => _d(_s.balanceFor(id));

  @override
  Future<void> enrolStudent(Student s, {required String guardianName, required String guardianPhone, required String byName}) async {
    // in Supabase: insert profiles(guardian) + students + student_guardians
    final gid = 'g-${guardianPhone.replaceAll(RegExp(r'\D'), '')}';
    _s.enrolStudent(s, gid, byName: byName);
  }

  @override
  Future<List<PaymentRecord>> recentPayments({int limit = 50}) =>
      _d((List.of(_s.payments)..sort((a, b) => b.payment.paidAt.compareTo(a.payment.paidAt))).take(limit).toList());

  @override
  Future<Payment> postPayment(String studentId, int amount, PaymentMethod method, String? reference, {required String byName}) async {
    final p = Payment(id: _s.nextId('p'), receiptNo: _s.nextReceiptNo(), amount: amount, method: method, paidAt: DateTime.now(), reference: reference);
    _s.postPayment(studentId, p, byName: byName);
    return p;
  }

  @override
  Future<List<ReportCard>> reportCards() => _d(List.of(_s.reportCards));
  @override
  Future<void> publishReport(String id, {required String byName}) async => _s.publishReport(id, byName: byName);

  @override
  Future<List<ClinicVisit>> clinicVisitsToday() {
    final n = DateTime.now();
    return _d(_s.clinicVisits.where((v) => v.visitedAt.year == n.year && v.visitedAt.month == n.month && v.visitedAt.day == n.day).toList()
      ..sort((a, b) => b.visitedAt.compareTo(a.visitedAt)));
  }
  @override
  Future<List<ClinicVisit>> referralsThisTerm() => _d(_s.clinicVisits.where((v) => v.outcome == VisitOutcome.referred).toList());
  @override
  Future<List<MedicineStock>> medicines() => _d(_s.medicines);
  @override
  Future<void> recordVisit(ClinicVisit v, {required String byName}) async => _s.recordClinicVisit(v, byName: byName);

  @override
  Future<List<DayMenu?>> weekMenu(DateTime monday) =>
      _d(List.generate(7, (i) => _s.menuFor(DateTime(monday.year, monday.month, monday.day + i))));
  @override
  Future<void> setMenu(DayMenu m, {required String byName}) async => _s.setMenu(m, byName: byName);

  @override
  Future<List<SchoolEvent>> events() => _d(List.of(_s.events));
  @override
  Future<void> addEvent(SchoolEvent e, {required String byName}) async => _s.addEvent(e, byName: byName);

  @override
  Future<void> setRequisitionStatus(String id, RequisitionStatus s, {required String byName}) async => _s.setRequisitionStatus(id, s, byName: byName);
  @override
  Future<List<StockItem>> stock() => _d(_s.stockItems);
}
