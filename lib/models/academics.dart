/// One subject row on a report card. Marks are written by the subject
/// teacher (staff app), locked 7 days after the assessment, and released to
/// parents only when the DOS/Director publishes the report.
class SubjectResult {
  final String subject;
  final int catScore;
  final int catOutOf;
  final int examScore;
  final int examOutOf;
  final String grade; // D1, D2, C3 ... F9
  final String? teacherComment;

  const SubjectResult({
    required this.subject,
    required this.catScore,
    required this.catOutOf,
    required this.examScore,
    required this.examOutOf,
    required this.grade,
    this.teacherComment,
  });

  int get total => catScore + examScore;
  int get totalOutOf => catOutOf + examOutOf;

  factory SubjectResult.fromMap(Map<String, dynamic> m) => SubjectResult(
    subject: (m['subject'] as String?) ?? '',
    catScore: ((m['cat_score'] as num?) ?? 0).toInt(),
    catOutOf: ((m['cat_out_of'] as num?) ?? 40).toInt(),
    examScore: ((m['exam_score'] as num?) ?? 0).toInt(),
    examOutOf: ((m['exam_out_of'] as num?) ?? 60).toInt(),
    grade: (m['grade'] as String?) ?? '—',
    teacherComment: m['teacher_comment'] as String?,
  );
}

enum ReportStatus {
  draft, // teachers still entering
  review, // DOS reviewing
  published; // visible to parents

  static ReportStatus fromKey(String? k) => ReportStatus.values.firstWhere(
    (e) => e.name == k,
    orElse: () => ReportStatus.draft,
  );
}

class ReportCard {
  final String id;
  final String studentId;
  final String termId;
  final String termLabel;
  final String className;
  final int? position;
  final int? classSize;
  final List<SubjectResult> results;
  final String? classTeacherComment;
  final String? classTeacherName;
  final String? headteacherComment;
  final DateTime? publishedAt;
  final ReportStatus status;
  final String? pdfUrl;

  const ReportCard({
    required this.id,
    required this.studentId,
    required this.termId,
    required this.termLabel,
    required this.className,
    required this.results,
    required this.status,
    this.position,
    this.classSize,
    this.classTeacherComment,
    this.classTeacherName,
    this.headteacherComment,
    this.publishedAt,
    this.pdfUrl,
  });

  bool get isPublished => status == ReportStatus.published;
  String get positionLabel =>
      position == null ? '—' : 'Position $position of ${classSize ?? '—'}';

  factory ReportCard.fromMap(
    Map<String, dynamic> m, {
    List<SubjectResult> results = const [],
  }) => ReportCard(
    id: m['id'] as String,
    studentId: m['student_id'] as String,
    termId: m['term_id'] as String,
    termLabel: (m['term_label'] as String?) ?? '',
    className: (m['class_name'] as String?) ?? '',
    position: (m['position'] as num?)?.toInt(),
    classSize: (m['class_size'] as num?)?.toInt(),
    results: results,
    classTeacherComment: m['class_teacher_comment'] as String?,
    classTeacherName: m['class_teacher_name'] as String?,
    headteacherComment: m['headteacher_comment'] as String?,
    publishedAt: m['published_at'] == null
        ? null
        : DateTime.tryParse(m['published_at'].toString()),
    status: ReportStatus.fromKey(m['status'] as String?),
    pdfUrl: m['pdf_url'] as String?,
  );
}
