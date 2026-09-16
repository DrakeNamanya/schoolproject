import '../../models/academics.dart';
import '../../models/clinic.dart';
import '../../models/fees.dart';
import '../../models/school.dart';
import '../../models/student.dart';
import '../parent_repository.dart';

/// In-memory seed data mirroring design_reference/parent/index.html so the
/// parent shell renders before Supabase credentials are configured. The
/// shapes are identical to what the Supabase repository returns.
class MockParentRepository implements ParentRepository {
  static final _now = DateTime(2026, 7, 9, 14, 2);

  static final _term = Term(
    id: 'term-2026-2',
    year: 2026,
    number: 2,
    startsOn: DateTime(2026, 5, 25),
    endsOn: DateTime(2026, 8, 21),
    feesDueOn: DateTime(2026, 7, 24),
    isCurrent: true,
  );

  static final _aisha = Student(
    id: 'stu-00478',
    admissionNo: 'TGS/2024/00478',
    firstName: 'Aisha',
    surname: 'Nakato',
    className: 'S2 East',
    house: 'Green',
    isBoarder: true,
    dormitory: 'Kwagala dormitory, bed 14',
    dateOfBirth: DateTime(2011, 3, 14),
    admittedOn: DateTime(2024, 2, 3),
  );

  static final _grace = Student(
    id: 'stu-00612',
    admissionNo: 'TGS/2025/00612',
    firstName: 'Grace',
    surname: 'Nakato',
    className: 'S1 North',
    house: 'Blue',
    isBoarder: true,
    dormitory: 'Kisubi dormitory, bed 3',
    dateOfBirth: DateTime(2012, 9, 2),
    admittedOn: DateTime(2025, 2, 3),
  );

  Future<T> _delay<T>(T v) =>
      Future.delayed(const Duration(milliseconds: 250), () => v);

  @override
  Future<List<Student>> myChildren(String guardianUserId) =>
      _delay([_aisha, _grace]);

  @override
  Future<StudentSummary> summary(String studentId) => _delay(
    studentId == _aisha.id
        ? const StudentSummary(
            studentId: 'stu-00478',
            attendancePct: 96,
            position: 12,
            classSize: 78,
            clinicVisitsThisTerm: 2,
          )
        : const StudentSummary(
            studentId: 'stu-00612',
            attendancePct: 99,
            position: 4,
            classSize: 84,
            clinicVisitsThisTerm: 0,
          ),
  );

  @override
  Future<Term> currentTerm() => _delay(_term);

  @override
  Future<FeeStatement> feeStatement(String studentId, String termId) {
    if (studentId == _grace.id) {
      return _delay(
        FeeStatement(
          studentId: studentId,
          term: _term,
          lines: const [
            FeeLine(id: 'l1', label: 'Tuition', amount: 1200000),
            FeeLine(id: 'l2', label: 'Boarding', amount: 450000),
            FeeLine(id: 'l3', label: 'Lunch programme', amount: 180000),
          ],
          payments: [
            Payment(
              id: 'p1',
              receiptNo: 'R-2026-0702',
              amount: 1830000,
              method: PaymentMethod.bank,
              paidAt: DateTime(2026, 6, 2, 11, 40),
            ),
          ],
        ),
      );
    }
    return _delay(
      FeeStatement(
        studentId: studentId,
        term: _term,
        lines: const [
          FeeLine(id: 'l1', label: 'Tuition', amount: 1200000),
          FeeLine(id: 'l2', label: 'Boarding', amount: 450000),
          FeeLine(id: 'l3', label: 'Lunch programme', amount: 180000),
          FeeLine(id: 'l4', label: 'Uniforms', amount: 70000),
        ],
        payments: [
          Payment(
            id: 'p1',
            receiptNo: 'R-2026-0611',
            amount: 1100000,
            method: PaymentMethod.bank,
            paidAt: DateTime(2026, 5, 28, 10, 5),
            reference: 'Stanbic · DEP 4471',
          ),
          Payment(
            id: 'p2',
            receiptNo: 'R-2026-0891',
            amount: 350000,
            method: PaymentMethod.mtn,
            paidAt: DateTime(2026, 7, 9, 9, 12),
            reference: 'MM 8813402771',
          ),
        ],
      ),
    );
  }

  @override
  Future<List<PaymentChannel>> paymentChannels() => _delay(const [
    PaymentChannel(
      method: PaymentMethod.mtn,
      title: 'MTN Mobile Money',
      instruction: 'Dial *165# · school code 402108',
    ),
    PaymentChannel(
      method: PaymentMethod.airtel,
      title: 'Airtel Money',
      instruction: 'Merchant code 402108',
    ),
    PaymentChannel(
      method: PaymentMethod.bank,
      title: 'Stanbic Bank deposit',
      instruction: 'A/C 9030002187 · TGS Ltd',
    ),
  ]);

  @override
  Future<ReportCard?> latestPublishedReport(String studentId) {
    if (studentId != _aisha.id) return _delay(null);
    return _delay(
      ReportCard(
        id: 'rc-1',
        studentId: studentId,
        termId: _term.id,
        termLabel: 'Term 2 · 2026',
        className: 'S2 East',
        position: 12,
        classSize: 78,
        status: ReportStatus.published,
        publishedAt: DateTime(2026, 7, 9),
        classTeacherName: 'Ms. Kabuye R.',
        classTeacherComment:
            'Aisha is a diligent and self-motivated girl. She should continue to work on the presentation of her Physics practicals. Well done this term.',
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
      ),
    );
  }

  @override
  Future<List<ClinicVisit>> clinicVisits(String studentId, {int limit = 20}) {
    if (studentId != _aisha.id) return _delay(const []);
    return _delay([
      ClinicVisit(
        id: 'cv-2',
        studentId: studentId,
        visitedAt: DateTime(2026, 7, 9, 10, 24),
        complaint: 'Headache · mild fever',
        notes:
            'Complaining of headache and mild fever. Paracetamol 500 mg administered. Advised rest until lunch. Returned to class after break.',
        treatment: 'Paracetamol 500 mg',
        vitals: const [
          Vital('Temp', '37.9°C'),
          Vital('BP', '108/68'),
          Vital('Pulse', '88'),
          Vital('Wt', '46 kg'),
        ],
        outcome: VisitOutcome.followUp,
        followUpNote: 'Follow up 24 h',
        recordedBy: 'Nurse Alice N.',
      ),
      ClinicVisit(
        id: 'cv-1',
        studentId: studentId,
        visitedAt: DateTime(2026, 6, 21, 14, 11),
        complaint: 'Minor cut · left knee',
        notes:
            'Grazed knee during sports. Cleaned, dressed, and returned to games with plaster. No further action needed.',
        vitals: const [Vital('Temp', '36.6°C'), Vital('Wound', 'Superficial')],
        outcome: VisitOutcome.discharged,
        recordedBy: 'Nurse Alice N.',
      ),
    ]);
  }

  @override
  Future<DayMenu?> menuFor(DateTime date) => _delay(
    DayMenu(
      date: date,
      breakfast: const Meal('Porridge & bread', 'Millet, milk tea'),
      lunch: const Meal('Posho & beans', 'Steamed cabbage'),
      supper: const Meal('Rice & fish stew', 'Sukuma wiki, fruit'),
    ),
  );

  @override
  Future<List<SchoolEvent>> upcomingEvents({int limit = 10}) => _delay([
    SchoolEvent(id: 'e1', title: 'S4 Mock paper 1 · Mathematics', startsAt: DateTime(2026, 7, 10, 8, 30), endsAt: DateTime(2026, 7, 10, 11), venue: 'Main hall', category: EventCategory.academic),
    SchoolEvent(id: 'e2', title: 'Inter-house MDD final', startsAt: DateTime(2026, 7, 12, 14), venue: 'Assembly hall', category: EventCategory.coCurricular),
    SchoolEvent(id: 'e3', title: 'Term 2 Visitation Day', startsAt: DateTime(2026, 7, 27, 10), endsAt: DateTime(2026, 7, 27, 14), audience: 'Boarding parents', category: EventCategory.community, highlight: true),
    SchoolEvent(id: 'e4', title: 'Report cards released', startsAt: DateTime(2026, 7, 28, 8), venue: 'Available in app', category: EventCategory.academic),
  ]);

  @override
  Future<List<SchoolDocument>> documents(String studentId) => _delay([
    const SchoolDocument(id: 'd1', title: 'Term 2 fees breakdown', subtitle: 'PDF · 340 KB', url: ''),
    const SchoolDocument(id: 'd2', title: 'School calendar 2026', subtitle: 'PDF · 220 KB', url: ''),
    const SchoolDocument(id: 'd3', title: 'Parent handbook · 2026 ed.', subtitle: 'PDF · 1.4 MB', url: ''),
    SchoolDocument(id: 'd4', title: 'Safe release · pickup consent', subtitle: 'Signed 03 Feb 2024', url: '', studentId: studentId),
  ]);

  @override
  Future<List<Notice>> notices(String guardianUserId, {int limit = 20}) =>
      _delay([
        Notice(id: 'n1', kind: NoticeKind.payment, title: 'Receipt R-2026-0891', subtitle: 'MTN Mobile Money · 09 Jul, 09:12', at: DateTime(2026, 7, 9, 9, 12), amount: 350000, studentId: _aisha.id),
        Notice(id: 'n2', kind: NoticeKind.clinic, title: 'Clinic: headache, paracetamol given', subtitle: 'Nurse Alice N. · 09 Jul, 10:24', at: DateTime(2026, 7, 9, 10, 24), studentId: _aisha.id),
        Notice(id: 'n3', kind: NoticeKind.event, title: 'Visitation Day · 27 Jul', subtitle: 'School hall · 10:00–14:00', at: DateTime(2026, 7, 8, 16)),
      ]);

  @override
  Future<void> markNoticeRead(String noticeId) async {}

  static DateTime get now => _now;
}
