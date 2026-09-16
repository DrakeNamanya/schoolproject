import '../../models/staff.dart';
import '../staff_repository.dart';

/// Seeded in-memory staff data (Mr. Ssekandi B., Physics/Math teacher and
/// class teacher of S2 East). Writes mutate in-memory state so the demo
/// behaves like the real backend within a session.
class MockStaffRepository implements StaffRepository {
  Future<T> _d<T>(T v) => Future.delayed(const Duration(milliseconds: 200), () => v);

  bool _auto = true;

  static const _fence = Geofence(
    id: 'fence-main',
    name: 'Main campus',
    lat: 0.3476,
    lng: 32.5825,
    radiusM: 120,
    graceMinutes: 15,
  );

  final List<AttendanceEvent> _events = [
    AttendanceEvent(
      id: 'ev-1',
      kind: AttendanceKind.autoIn,
      at: DateTime.now().copyWith(hour: 7, minute: 38, second: 0),
      accuracyM: 6,
      distanceM: 42,
    ),
  ];

  static const _s2e = SchoolClass(id: 'cls-s2e', name: 'S2 East', level: 2, classTeacherId: 'demo-teacher', size: 38);
  static const _s3w = SchoolClass(id: 'cls-s3w', name: 'S3 West', level: 3, size: 34);
  static const _s3e = SchoolClass(id: 'cls-s3e', name: 'S3 East', level: 3, size: 32);
  static const _s2n = SchoolClass(id: 'cls-s2n', name: 'S2 North', level: 2, size: 36);
  static const _phy = Subject(id: 'sub-phy', code: 'PHY', name: 'Physics');
  static const _mat = Subject(id: 'sub-mat', code: 'MAT', name: 'Mathematics');

  static const _assignments = [
    TeachingAssignment(id: 'ta-1', schoolClass: _s3e, subject: _phy),
    TeachingAssignment(id: 'ta-2', schoolClass: _s3w, subject: _phy),
    TeachingAssignment(id: 'ta-3', schoolClass: _s2e, subject: _mat, isClassTeacher: true),
    TeachingAssignment(id: 'ta-4', schoolClass: _s2n, subject: _mat),
  ];

  final Map<String, List<Assessment>> _assessments = {
    'ta-1': [
      Assessment(id: 'as-1', assignmentId: 'ta-1', title: 'CAT 1', outOf: 30, assessedOn: DateTime.now().subtract(const Duration(days: 21)), locksAt: DateTime.now().subtract(const Duration(days: 14))),
      Assessment(id: 'as-2', assignmentId: 'ta-1', title: 'CAT 2', outOf: 40, assessedOn: DateTime.now().subtract(const Duration(days: 2)), locksAt: DateTime.now().add(const Duration(days: 5))),
    ],
    'ta-3': [
      Assessment(id: 'as-3', assignmentId: 'ta-3', title: 'CAT 2', outOf: 40, assessedOn: DateTime.now().subtract(const Duration(days: 1)), locksAt: DateTime.now().add(const Duration(days: 6))),
    ],
  };

  static const _rosters = <String, List<(String, String, String)>>{
    'cls-s3e': [
      ('stu-a1', 'Nakato Aisha', 'TGS/2024/00478'),
      ('stu-a2', 'Akello Prossy', 'TGS/2024/00512'),
      ('stu-a3', 'Kembabazi Esther', 'TGS/2023/00301'),
      ('stu-a4', 'Lamunu Mercy', 'TGS/2022/00159'),
      ('stu-a5', 'Namara Miriam', 'TGS/2023/00288'),
      ('stu-a6', 'Ssebugwawo Betty', 'TGS/2023/00214'),
      ('stu-a7', 'Tumwesigye Naome', 'TGS/2023/00233'),
    ],
    'cls-s2e': [
      ('stu-00478', 'Nakato Aisha', 'TGS/2024/00478'),
      ('stu-b2', 'Namuli Angel', 'TGS/2024/00521'),
      ('stu-b3', 'Nabirye Joan', 'TGS/2024/00490'),
      ('stu-b4', 'Atim Sharon', 'TGS/2024/00503'),
      ('stu-b5', 'Kirabo Faith', 'TGS/2024/00499'),
      ('stu-b6', 'Nansubuga Ritah', 'TGS/2024/00511'),
      ('stu-b7', 'Apio Winnie', 'TGS/2024/00485'),
      ('stu-b8', 'Mbabazi Doreen', 'TGS/2024/00517'),
    ],
  };

  final Map<String, List<MarkEntry>> _marks = {
    'as-2': [
      MarkEntry(studentId: 'stu-a1', studentName: 'Nakato Aisha', admissionNo: 'TGS/2024/00478', score: 32, comment: 'Strong grasp of mechanics'),
      MarkEntry(studentId: 'stu-a2', studentName: 'Akello Prossy', admissionNo: 'TGS/2024/00512', score: 30, comment: 'Very good work'),
      MarkEntry(studentId: 'stu-a3', studentName: 'Kembabazi Esther', admissionNo: 'TGS/2023/00301', score: 28),
      MarkEntry(studentId: 'stu-a4', studentName: 'Lamunu Mercy', admissionNo: 'TGS/2022/00159', score: 35, comment: 'Excellent'),
      MarkEntry(studentId: 'stu-a5', studentName: 'Namara Miriam', admissionNo: 'TGS/2023/00288', score: 24),
      MarkEntry(studentId: 'stu-a6', studentName: 'Ssebugwawo Betty', admissionNo: 'TGS/2023/00214'),
      MarkEntry(studentId: 'stu-a7', studentName: 'Tumwesigye Naome', admissionNo: 'TGS/2023/00233'),
    ],
  };

  final Map<String, List<RollCallEntry>> _roll = {};

  final List<StaffAlert> _alerts = [
    StaffAlert(id: 'al-1', severity: 'danger', source: 'DOS office', title: 'Off-campus during class hours', body: 'Ms. Nabbosa J. flagged 420 m from campus during her 09:45 lesson. Please review.', at: DateTime.now().copyWith(hour: 14, minute: 0)),
    StaffAlert(id: 'al-2', severity: 'warn', source: 'Academics', title: 'Marks entry window closes in 5 days', body: 'Physics S3 East CAT 2 marks lock automatically 7 days after the assessment date.', at: DateTime.now().copyWith(hour: 13, minute: 15)),
    StaffAlert(id: 'al-3', severity: 'success', source: 'System', title: 'Auto check-in accepted', body: '07:38 · Inside campus geofence, ±6 m.', at: DateTime.now().copyWith(hour: 7, minute: 38), read: true),
    StaffAlert(id: 'al-4', severity: 'info', source: 'Procurement', title: 'Requisition #REQ-0341 approved', body: 'Lab consumables · UGX 480,000 · Director signed off.', at: DateTime.now().subtract(const Duration(days: 1)).copyWith(hour: 16, minute: 22), read: true),
    StaffAlert(id: 'al-5', severity: 'success', source: 'System', title: 'Auto check-out at 17:04', body: 'Departed geofence · full day 9 h 32 m recorded.', at: DateTime.now().subtract(const Duration(days: 1)).copyWith(hour: 17, minute: 4), read: true),
  ];

  // ------------------------------------------------------------------

  @override
  Future<StaffProfile> profile(String userId) => _d(StaffProfile(
    userId: userId,
    staffNo: 'STAFF/2021/041',
    department: 'Physics',
    jobTitle: 'Teacher · Class teacher S2 East',
    dutyStart: '07:30',
    dutyEnd: '17:00',
    weeklyTargetMinutes: 2400,
    autoCheckin: _auto,
  ));

  @override
  Future<void> setAutoCheckin(String userId, bool on) async => _auto = on;

  @override
  Future<Geofence> activeGeofence() => _d(_fence);

  @override
  Future<List<AttendanceEvent>> todayEvents(String userId) => _d(List.of(_events.reversed));

  @override
  Future<AttendanceEvent> recordEvent(String userId, AttendanceKind kind, {double? lat, double? lng, double? accuracyM, double? distanceM}) async {
    final e = AttendanceEvent(id: 'ev-${_events.length + 1}', kind: kind, at: DateTime.now(), accuracyM: accuracyM, distanceM: distanceM);
    _events.add(e);
    if (kind == AttendanceKind.autoIn) {
      _alerts.insert(0, StaffAlert(id: 'al-${_alerts.length + 1}', severity: 'success', source: 'System', title: 'Auto check-in accepted', body: '${_hm(e.at)} · Inside campus geofence, ±${accuracyM?.round() ?? 6} m.', at: e.at));
    } else if (kind == AttendanceKind.flaggedOffCampus) {
      _alerts.insert(0, StaffAlert(id: 'al-${_alerts.length + 1}', severity: 'warn', source: 'Geofence', title: 'You appear to be off-campus', body: 'Detected ${distanceM?.round() ?? 0} m from campus during a scheduled lesson.', at: e.at));
    }
    return e;
  }

  @override
  Future<List<TimetableSlot>> slotsFor(String userId, int weekday) {
    if (weekday > 5) return _d(const []);
    return _d([
      TimetableSlot(id: 's1', weekday: weekday, startsAt: '07:30', endsAt: '08:15', title: 'Physics · S3 West', room: 'Lab 2', classSize: 34),
      TimetableSlot(id: 's2', weekday: weekday, startsAt: '08:15', endsAt: '09:00', title: 'Physics · S3 East', room: 'Lab 2', classSize: 32),
      TimetableSlot(id: 's3', weekday: weekday, startsAt: '09:00', endsAt: '09:45', title: 'Math · S2 East', room: 'Room 14', classSize: 38),
      TimetableSlot(id: 's4', weekday: weekday, startsAt: '10:00', endsAt: '10:45', title: 'Break duty', room: 'Green quadrant'),
      TimetableSlot(id: 's5', weekday: weekday, startsAt: '11:30', endsAt: '12:15', title: 'Math · S2 North', room: 'Room 08', classSize: 36),
      TimetableSlot(id: 's6', weekday: weekday, startsAt: '14:00', endsAt: '15:00', title: 'Physics · S3 East (double)', room: 'Lab 2', classSize: 32),
      TimetableSlot(id: 's7', weekday: weekday, startsAt: '15:45', endsAt: '17:00', title: 'Prep · S4 mock revision', room: 'Library'),
    ]);
  }

  @override
  Future<List<TeachingAssignment>> assignments(String userId) => _d(_assignments);

  @override
  Future<List<Assessment>> assessments(String assignmentId) => _d(List.of(_assessments[assignmentId] ?? const []));

  @override
  Future<Assessment> createAssessment(String assignmentId, {required String title, required int outOf, required DateTime assessedOn}) async {
    final a = Assessment(id: 'as-${DateTime.now().millisecondsSinceEpoch}', assignmentId: assignmentId, title: title, outOf: outOf, assessedOn: assessedOn, locksAt: assessedOn.add(const Duration(days: 7)));
    (_assessments[assignmentId] ??= []).add(a);
    return a;
  }

  @override
  Future<List<MarkEntry>> marks(String assessmentId) {
    if (_marks[assessmentId] == null) {
      final a = _assessments.values.expand((l) => l).firstWhere((x) => x.id == assessmentId);
      final ta = _assignments.firstWhere((t) => t.id == a.assignmentId);
      final roster = _rosters[ta.schoolClass.id] ?? _rosters['cls-s3e']!;
      _marks[assessmentId] = roster.map((r) => MarkEntry(studentId: r.$1, studentName: r.$2, admissionNo: r.$3)).toList();
    }
    return _d(_marks[assessmentId]!.map((m) => MarkEntry(studentId: m.studentId, studentName: m.studentName, admissionNo: m.admissionNo, score: m.score, comment: m.comment)).toList());
  }

  @override
  Future<void> saveMarks(String assessmentId, List<MarkEntry> entries, String enteredBy) async {
    _marks[assessmentId] = entries.map((m) => MarkEntry(studentId: m.studentId, studentName: m.studentName, admissionNo: m.admissionNo, score: m.score, comment: m.comment)).toList();
  }

  @override
  Future<List<RollCallEntry>> rollCall(String classId, DateTime date) {
    final key = '$classId-${date.year}${date.month}${date.day}';
    _roll[key] ??= (_rosters[classId] ?? const []).map((r) => RollCallEntry(studentId: r.$1, studentName: r.$2, admissionNo: r.$3)).toList();
    return _d(_roll[key]!.map((e) => RollCallEntry(studentId: e.studentId, studentName: e.studentName, admissionNo: e.admissionNo, present: e.present)).toList());
  }

  @override
  Future<void> saveRollCall(String classId, DateTime date, List<RollCallEntry> entries, String markedBy) async {
    _roll['$classId-${date.year}${date.month}${date.day}'] = entries;
  }

  @override
  Future<List<TimesheetDay>> thisWeek(String userId) {
    final now = DateTime.now();
    final mon = now.subtract(Duration(days: now.weekday - 1));
    final days = <TimesheetDay>[];
    for (var i = 0; i < 5; i++) {
      final d = DateTime(mon.year, mon.month, mon.day + i);
      if (d.isBefore(DateTime(now.year, now.month, now.day))) {
        days.add(TimesheetDay(date: d, firstIn: d.copyWith(hour: 7, minute: 29 + i), lastOut: d.copyWith(hour: 17, minute: 4 - i), minutesWorked: 9 * 60 + 32 - i * 3, status: 'full_day'));
      } else if (d.day == now.day && d.month == now.month) {
        final first = _events.where((e) => e.kind.isIn).map((e) => e.at).fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);
        final mins = first == null ? 0 : now.difference(first).inMinutes;
        days.add(TimesheetDay(date: d, firstIn: first, minutesWorked: mins, status: 'in_progress'));
      } else {
        days.add(TimesheetDay(date: d, minutesWorked: 0, status: 'scheduled'));
      }
    }
    return _d(days);
  }

  @override
  Future<List<WeekSummary>> previousWeeks(String userId, {int count = 3}) => _d(const [
    WeekSummary('Week 4 · 30 Jun–04 Jul', 41 * 60 + 8),
    WeekSummary('Week 3 · 23–27 Jun', 40 * 60 + 2),
    WeekSummary('Week 2 · 16–20 Jun', 39 * 60 + 44),
  ]);

  @override
  Future<List<StaffAlert>> alerts(String userId) => _d(List.of(_alerts));

  @override
  Future<void> markAlertRead(String alertId) async {
    final i = _alerts.indexWhere((a) => a.id == alertId);
    if (i >= 0) _alerts[i] = _alerts[i].asRead();
  }

  static String _hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
