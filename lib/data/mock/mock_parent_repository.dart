import '../../models/academics.dart';
import '../../models/clinic.dart';
import '../../models/fees.dart';
import '../../models/school.dart';
import '../../models/student.dart';
import '../parent_repository.dart';
import 'demo_store.dart';

/// Parent reads against the shared [DemoStore], so anything the bursar,
/// nurse, DOS, cook or registrar writes in the admin console shows up here.
class MockParentRepository implements ParentRepository {
  final DemoStore _s = DemoStore.instance;
  Future<T> _d<T>(T v) => Future.delayed(const Duration(milliseconds: 150), () => v);

  @override
  Future<List<Student>> myChildren(String guardianUserId) => _d(_s.childrenOf(guardianUserId));

  @override
  Future<StudentSummary> summary(String studentId) =>
      _d(_s.summaries[studentId] ?? StudentSummary(studentId: studentId, attendancePct: 0, clinicVisitsThisTerm: 0));

  @override
  Future<Term> currentTerm() => _d(_s.currentTerm);

  @override
  Future<FeeStatement> feeStatement(String studentId, String termId) => _d(FeeStatement(
    studentId: studentId,
    term: _s.currentTerm,
    lines: _s.feeLinesFor(studentId),
    payments: _s.paymentsFor(studentId).map((p) => p.payment).toList(),
  ));

  @override
  Future<List<PaymentChannel>> paymentChannels() => _d(_s.channels);

  @override
  Future<ReportCard?> latestPublishedReport(String studentId) {
    final l = _s.reportCards.where((r) => r.studentId == studentId && r.isPublished).toList()
      ..sort((a, b) => (b.publishedAt ?? DateTime(0)).compareTo(a.publishedAt ?? DateTime(0)));
    return _d(l.isEmpty ? null : l.first);
  }

  @override
  Future<List<ClinicVisit>> clinicVisits(String studentId, {int limit = 20}) => _d(
    (_s.clinicVisits.where((v) => v.studentId == studentId).toList()
          ..sort((a, b) => b.visitedAt.compareTo(a.visitedAt)))
        .take(limit)
        .toList(),
  );

  @override
  Future<DayMenu?> menuFor(DateTime date) => _d(_s.menuFor(date));

  @override
  Future<List<SchoolEvent>> upcomingEvents({int limit = 10}) => _d(
    (_s.events.where((e) => e.startsAt.isAfter(DateTime.now().subtract(const Duration(hours: 12)))).toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt)))
        .take(limit)
        .toList(),
  );

  @override
  Future<List<SchoolDocument>> documents(String studentId) =>
      _d(_s.documents.where((d) => d.studentId == null || d.studentId == studentId).toList());

  @override
  Future<List<Notice>> notices(String guardianUserId, {int limit = 20}) =>
      _d(_s.noticesFor(guardianUserId).take(limit).toList());

  @override
  Future<void> markNoticeRead(String noticeId) async => _s.markNoticeRead(noticeId);
}
