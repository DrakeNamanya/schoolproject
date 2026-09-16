// Staff-side models. Table mapping in docs/DATA_MODEL.md §3, §9.

class StaffProfile {
  final String userId;
  final String staffNo; // STAFF/2021/041
  final String? department; // Physics
  final String? jobTitle; // Teacher
  final String dutyStart; // 07:30
  final String dutyEnd; // 17:00
  final int weeklyTargetMinutes;
  final bool autoCheckin;

  const StaffProfile({
    required this.userId,
    required this.staffNo,
    required this.dutyStart,
    required this.dutyEnd,
    required this.weeklyTargetMinutes,
    this.department,
    this.jobTitle,
    this.autoCheckin = true,
  });

  String get dutyLabel => '$dutyStart–$dutyEnd';

  factory StaffProfile.fromMap(Map<String, dynamic> m) => StaffProfile(
    userId: m['user_id'] as String,
    staffNo: (m['staff_no'] as String?) ?? '',
    department: m['department'] as String?,
    jobTitle: m['job_title'] as String?,
    dutyStart: _hm(m['duty_start']),
    dutyEnd: _hm(m['duty_end']),
    weeklyTargetMinutes: ((m['weekly_target_minutes'] as num?) ?? 2400).toInt(),
    autoCheckin: (m['auto_checkin'] as bool?) ?? true,
  );
}

class SchoolClass {
  final String id;
  final String name; // S2 East
  final int level;
  final String? classTeacherId;
  final int size;

  const SchoolClass({
    required this.id,
    required this.name,
    required this.level,
    this.classTeacherId,
    this.size = 0,
  });

  factory SchoolClass.fromMap(Map<String, dynamic> m) => SchoolClass(
    id: m['id'] as String,
    name: (m['name'] as String?) ?? '',
    level: ((m['level'] as num?) ?? 0).toInt(),
    classTeacherId: m['class_teacher_id'] as String?,
    size: ((m['size'] as num?) ?? 0).toInt(),
  );
}

class Subject {
  final String id;
  final String code;
  final String name;
  const Subject({required this.id, required this.code, required this.name});

  factory Subject.fromMap(Map<String, dynamic> m) => Subject(
    id: m['id'] as String,
    code: (m['code'] as String?) ?? '',
    name: (m['name'] as String?) ?? '',
  );
}

/// teacher × class × subject for the current term.
class TeachingAssignment {
  final String id;
  final SchoolClass schoolClass;
  final Subject subject;
  final bool isClassTeacher; // can do roll call

  const TeachingAssignment({
    required this.id,
    required this.schoolClass,
    required this.subject,
    this.isClassTeacher = false,
  });

  String get label => '${subject.name} · ${schoolClass.name}';
}

class TimetableSlot {
  final String id;
  final int weekday; // 1 = Mon
  final String startsAt; // 07:30
  final String endsAt;
  final String title; // Physics · S3 West  or  Break duty
  final String? room;
  final int? classSize;

  const TimetableSlot({
    required this.id,
    required this.weekday,
    required this.startsAt,
    required this.endsAt,
    required this.title,
    this.room,
    this.classSize,
  });

  String get where =>
      [room, classSize == null ? null : '$classSize girls'].whereType<String>().join(' · ');

  /// done / now / upcoming relative to [now] (same weekday assumed).
  SlotState stateAt(DateTime now) {
    final s = _toMinutes(startsAt), e = _toMinutes(endsAt);
    final n = now.hour * 60 + now.minute;
    if (n >= e) return SlotState.done;
    if (n >= s) return SlotState.now;
    return SlotState.upcoming;
  }

  factory TimetableSlot.fromMap(Map<String, dynamic> m) => TimetableSlot(
    id: m['id'] as String,
    weekday: ((m['weekday'] as num?) ?? 1).toInt(),
    startsAt: _hm(m['starts_at']),
    endsAt: _hm(m['ends_at']),
    title: (m['title'] as String?) ?? '',
    room: m['room'] as String?,
    classSize: (m['class_size'] as num?)?.toInt(),
  );
}

enum SlotState { done, now, upcoming }

// ---------------------------------------------------------------------------
// Assessments & marks (teacher writes; feeds parent report card)
// ---------------------------------------------------------------------------

class Assessment {
  final String id;
  final String assignmentId;
  final String title; // CAT 2
  final int outOf;
  final DateTime assessedOn;
  final DateTime locksAt; // assessedOn + 7 days

  const Assessment({
    required this.id,
    required this.assignmentId,
    required this.title,
    required this.outOf,
    required this.assessedOn,
    required this.locksAt,
  });

  bool get isLocked => DateTime.now().isAfter(locksAt);
  int get daysToLock => locksAt.difference(DateTime.now()).inDays;

  factory Assessment.fromMap(Map<String, dynamic> m) {
    final on = DateTime.parse(m['assessed_on'].toString());
    return Assessment(
      id: m['id'] as String,
      assignmentId: (m['assignment_id'] as String?) ?? '',
      title: (m['title'] as String?) ?? '',
      outOf: ((m['out_of'] as num?) ?? 100).toInt(),
      assessedOn: on,
      locksAt: m['locks_at'] == null
          ? on.add(const Duration(days: 7))
          : DateTime.parse(m['locks_at'].toString()),
    );
  }
}

class MarkEntry {
  final String studentId;
  final String studentName;
  final String admissionNo;
  int? score;
  String? comment;

  MarkEntry({
    required this.studentId,
    required this.studentName,
    required this.admissionNo,
    this.score,
    this.comment,
  });

  String get initials {
    final p = studentName.split(' ');
    return p.length > 1 ? '${p[0][0]}${p[1][0]}' : p[0][0];
  }
}

// ---------------------------------------------------------------------------
// Roll call
// ---------------------------------------------------------------------------

class RollCallEntry {
  final String studentId;
  final String studentName;
  final String admissionNo;
  bool present;

  RollCallEntry({
    required this.studentId,
    required this.studentName,
    required this.admissionNo,
    this.present = true,
  });
}

// ---------------------------------------------------------------------------
// Geofence & attendance
// ---------------------------------------------------------------------------

class Geofence {
  final String id;
  final String name;
  final double lat, lng;
  final int radiusM;
  final int graceMinutes;

  const Geofence({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusM,
    required this.graceMinutes,
  });

  factory Geofence.fromMap(Map<String, dynamic> m) => Geofence(
    id: m['id'] as String,
    name: (m['name'] as String?) ?? 'Campus',
    lat: (m['lat'] as num).toDouble(),
    lng: (m['lng'] as num).toDouble(),
    radiusM: ((m['radius_m'] as num?) ?? 120).toInt(),
    graceMinutes: ((m['grace_minutes'] as num?) ?? 15).toInt(),
  );
}

enum AttendanceKind {
  autoIn,
  autoOut,
  manualIn,
  manualOut,
  flaggedOffCampus;

  String get key => switch (this) {
    AttendanceKind.autoIn => 'auto_in',
    AttendanceKind.autoOut => 'auto_out',
    AttendanceKind.manualIn => 'manual_in',
    AttendanceKind.manualOut => 'manual_out',
    AttendanceKind.flaggedOffCampus => 'flagged_off_campus',
  };

  static AttendanceKind fromKey(String? k) =>
      AttendanceKind.values.firstWhere((e) => e.key == k, orElse: () => AttendanceKind.autoIn);

  bool get isIn => this == AttendanceKind.autoIn || this == AttendanceKind.manualIn;
  bool get isOut => this == AttendanceKind.autoOut || this == AttendanceKind.manualOut;

  String get label => switch (this) {
    AttendanceKind.autoIn => 'Auto check-in via geofence',
    AttendanceKind.autoOut => 'Auto check-out',
    AttendanceKind.manualIn => 'Manual check-in',
    AttendanceKind.manualOut => 'Manual check-out',
    AttendanceKind.flaggedOffCampus => 'Flagged off-campus',
  };
}

class AttendanceEvent {
  final String id;
  final AttendanceKind kind;
  final DateTime at;
  final double? accuracyM;
  final double? distanceM;

  const AttendanceEvent({
    required this.id,
    required this.kind,
    required this.at,
    this.accuracyM,
    this.distanceM,
  });

  factory AttendanceEvent.fromMap(Map<String, dynamic> m) => AttendanceEvent(
    id: m['id'] as String,
    kind: AttendanceKind.fromKey(m['kind'] as String?),
    at: DateTime.parse(m['at'].toString()),
    accuracyM: (m['accuracy_m'] as num?)?.toDouble(),
    distanceM: (m['distance_m'] as num?)?.toDouble(),
  );
}

class TimesheetDay {
  final DateTime date;
  final DateTime? firstIn;
  final DateTime? lastOut;
  final int minutesWorked;
  final int lateMinutes;
  final String status; // full_day | partial | absent | in_progress | scheduled

  const TimesheetDay({
    required this.date,
    required this.minutesWorked,
    required this.status,
    this.firstIn,
    this.lastOut,
    this.lateMinutes = 0,
  });

  String get statusLabel => switch (status) {
    'full_day' => 'Full day',
    'partial' => 'Partial',
    'absent' => 'Absent',
    'in_progress' => 'In progress',
    _ => 'Scheduled',
  };

  factory TimesheetDay.fromMap(Map<String, dynamic> m) => TimesheetDay(
    date: DateTime.parse(m['on_date'].toString()),
    firstIn: m['first_in'] == null ? null : DateTime.parse(m['first_in'].toString()),
    lastOut: m['last_out'] == null ? null : DateTime.parse(m['last_out'].toString()),
    minutesWorked: ((m['minutes_worked'] as num?) ?? 0).toInt(),
    lateMinutes: ((m['late_minutes'] as num?) ?? 0).toInt(),
    status: (m['status'] as String?) ?? 'scheduled',
  );
}

class WeekSummary {
  final String label; // Week 4 · 30 Jun–04 Jul
  final int minutes;
  const WeekSummary(this.label, this.minutes);
}

class StaffAlert {
  final String id;
  final String severity; // danger | warn | success | info
  final String source;
  final String title;
  final String body;
  final DateTime at;
  final bool read;

  const StaffAlert({
    required this.id,
    required this.severity,
    required this.source,
    required this.title,
    required this.body,
    required this.at,
    this.read = false,
  });

  StaffAlert asRead() => StaffAlert(
    id: id, severity: severity, source: source, title: title, body: body, at: at, read: true,
  );

  factory StaffAlert.fromMap(Map<String, dynamic> m) => StaffAlert(
    id: m['id'] as String,
    severity: (m['severity'] as String?) ?? 'info',
    source: (m['source'] as String?) ?? 'System',
    title: (m['title'] as String?) ?? '',
    body: (m['body'] as String?) ?? '',
    at: DateTime.parse(m['created_at'].toString()),
    read: (m['read'] as bool?) ?? false,
  );
}

// ---------------------------------------------------------------------------

String _hm(dynamic v) {
  if (v == null) return '';
  final s = v.toString();
  return s.length >= 5 ? s.substring(0, 5) : s;
}

int _toMinutes(String hm) {
  final p = hm.split(':');
  if (p.length < 2) return 0;
  return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
}

String formatMinutes(int m) {
  final h = m ~/ 60, r = m % 60;
  if (h == 0) return '$r m';
  return '$h h ${r.toString().padLeft(2, '0')} m';
}
