/// A learner. Written by the Registrar; read by parents, teachers, bursar,
/// nurse. Never edited from the parent shell.
class Student {
  final String id;
  final String admissionNo; // TGS/2024/00478
  final String firstName;
  final String surname;
  final String className; // S2 East
  final String house; // Green
  final bool isBoarder;
  final String? dormitory; // Kwagala dormitory, bed 14
  final DateTime? dateOfBirth;
  final DateTime? admittedOn;
  final String? photoUrl;

  const Student({
    required this.id,
    required this.admissionNo,
    required this.firstName,
    required this.surname,
    required this.className,
    required this.house,
    required this.isBoarder,
    this.dormitory,
    this.dateOfBirth,
    this.admittedOn,
    this.photoUrl,
  });

  String get fullName => '$surname $firstName';
  String get shortName => '$surname ${firstName[0]}.';
  String get initials => '${surname[0]}${firstName[0]}'.toUpperCase();
  String get boardingLabel => isBoarder ? 'Boarding' : 'Day';

  factory Student.fromMap(Map<String, dynamic> m) => Student(
    id: m['id'] as String,
    admissionNo: (m['admission_no'] as String?) ?? '',
    firstName: (m['first_name'] as String?) ?? '',
    surname: (m['surname'] as String?) ?? '',
    className: (m['class_name'] as String?) ?? '',
    house: (m['house'] as String?) ?? '',
    isBoarder: (m['is_boarder'] as bool?) ?? false,
    dormitory: m['dormitory'] as String?,
    dateOfBirth: _date(m['date_of_birth']),
    admittedOn: _date(m['admitted_on']),
    photoUrl: m['photo_url'] as String?,
  );
}

/// Per-student summary shown on the parent hero card. Computed server-side
/// (view `v_student_summary`) from attendance, marks and clinic tables.
class StudentSummary {
  final String studentId;
  final double attendancePct; // 0-100
  final int? position;
  final int? classSize;
  final int clinicVisitsThisTerm;

  const StudentSummary({
    required this.studentId,
    required this.attendancePct,
    required this.clinicVisitsThisTerm,
    this.position,
    this.classSize,
  });

  String get positionLabel =>
      position == null ? '—' : '$position / ${classSize ?? '—'}';

  factory StudentSummary.fromMap(Map<String, dynamic> m) => StudentSummary(
    studentId: m['student_id'] as String,
    attendancePct: ((m['attendance_pct'] as num?) ?? 0).toDouble(),
    position: (m['position'] as num?)?.toInt(),
    classSize: (m['class_size'] as num?)?.toInt(),
    clinicVisitsThisTerm: ((m['clinic_visits'] as num?) ?? 0).toInt(),
  );
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}
