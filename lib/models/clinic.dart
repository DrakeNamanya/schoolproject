/// A clinic visit. Written ONLY by the Nurse. Read by the guardian, the
/// class teacher and clinic staff (least-privilege).
enum VisitOutcome {
  discharged,
  observing,
  followUp,
  referred;

  static VisitOutcome fromKey(String? k) => VisitOutcome.values.firstWhere(
    (e) => e.name == k,
    orElse: () => VisitOutcome.discharged,
  );

  String get label => switch (this) {
    VisitOutcome.discharged => 'Discharged',
    VisitOutcome.observing => 'Under observation',
    VisitOutcome.followUp => 'Follow up',
    VisitOutcome.referred => 'Referred',
  };
}

class Vital {
  final String label; // Temp, BP, Pulse, Wt
  final String value; // 37.9°C
  const Vital(this.label, this.value);

  factory Vital.fromMap(Map<String, dynamic> m) =>
      Vital((m['label'] as String?) ?? '', (m['value'] as String?) ?? '');
}

class ClinicVisit {
  final String id;
  final String studentId;
  final DateTime visitedAt;
  final String complaint; // Headache · mild fever
  final String notes;
  final List<Vital> vitals;
  final String? treatment; // Paracetamol 500 mg
  final VisitOutcome outcome;
  final String? followUpNote; // Follow up 24 h
  final String recordedBy; // Nurse Alice N.
  final String? referralFacility;

  const ClinicVisit({
    required this.id,
    required this.studentId,
    required this.visitedAt,
    required this.complaint,
    required this.notes,
    required this.vitals,
    required this.outcome,
    required this.recordedBy,
    this.treatment,
    this.followUpNote,
    this.referralFacility,
  });

  factory ClinicVisit.fromMap(Map<String, dynamic> m) => ClinicVisit(
    id: m['id'] as String,
    studentId: m['student_id'] as String,
    visitedAt: DateTime.parse(m['visited_at'].toString()),
    complaint: (m['complaint'] as String?) ?? '',
    notes: (m['notes'] as String?) ?? '',
    vitals: ((m['vitals'] as List?) ?? const [])
        .map((v) => Vital.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList(),
    treatment: m['treatment'] as String?,
    outcome: VisitOutcome.fromKey(m['outcome'] as String?),
    followUpNote: m['follow_up_note'] as String?,
    recordedBy: (m['recorded_by_name'] as String?) ?? 'Clinic',
    referralFacility: m['referral_facility'] as String?,
  );
}
