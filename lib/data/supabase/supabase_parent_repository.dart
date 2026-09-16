import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/academics.dart';
import '../../models/clinic.dart';
import '../../models/fees.dart';
import '../../models/school.dart';
import '../../models/student.dart';
import '../parent_repository.dart';

/// Supabase implementation. Table/column names match
/// supabase/migrations/0001_init.sql. RLS ensures a guardian only ever sees
/// rows for students linked to them through `student_guardians`.
class SupabaseParentRepository implements ParentRepository {
  SupabaseParentRepository(this._db);
  final SupabaseClient _db;

  @override
  Future<List<Student>> myChildren(String guardianUserId) async {
    final rows = await _db
        .from('student_guardians')
        .select('students(*)')
        .eq('guardian_id', guardianUserId);
    return (rows as List)
        .map((r) => r['students'])
        .whereType<Map>()
        .map((m) => Student.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  @override
  Future<StudentSummary> summary(String studentId) async {
    final row = await _db
        .from('v_student_summary')
        .select()
        .eq('student_id', studentId)
        .maybeSingle();
    if (row == null) {
      return StudentSummary(
        studentId: studentId,
        attendancePct: 0,
        clinicVisitsThisTerm: 0,
      );
    }
    return StudentSummary.fromMap(row);
  }

  @override
  Future<Term> currentTerm() async {
    final row = await _db
        .from('terms')
        .select()
        .eq('is_current', true)
        .limit(1)
        .single();
    return Term.fromMap(row);
  }

  @override
  Future<FeeStatement> feeStatement(String studentId, String termId) async {
    final term = Term.fromMap(
      await _db.from('terms').select().eq('id', termId).single(),
    );
    final lines = await _db
        .from('fee_lines')
        .select()
        .eq('student_id', studentId)
        .eq('term_id', termId);
    final payments = await _db
        .from('payments')
        .select()
        .eq('student_id', studentId)
        .eq('term_id', termId);
    final pays = (payments as List)
        .map((m) => Payment.fromMap(Map<String, dynamic>.from(m)))
        .toList()
      ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
    return FeeStatement(
      studentId: studentId,
      term: term,
      lines: (lines as List)
          .map((m) => FeeLine.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      payments: pays,
    );
  }

  @override
  Future<List<PaymentChannel>> paymentChannels() async {
    final rows = await _db
        .from('payment_channels')
        .select()
        .eq('active', true)
        .order('sort_order');
    return (rows as List)
        .map(
          (m) => PaymentChannel(
            method: PaymentMethod.fromKey(m['method'] as String?),
            title: (m['title'] as String?) ?? '',
            instruction: (m['instruction'] as String?) ?? '',
          ),
        )
        .toList();
  }

  @override
  Future<ReportCard?> latestPublishedReport(String studentId) async {
    final rc = await _db
        .from('report_cards')
        .select()
        .eq('student_id', studentId)
        .eq('status', 'published')
        .order('published_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (rc == null) return null;
    final results = await _db
        .from('report_card_results')
        .select()
        .eq('report_card_id', rc['id'])
        .order('sort_order');
    return ReportCard.fromMap(
      rc,
      results: (results as List)
          .map((m) => SubjectResult.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }

  @override
  Future<List<ClinicVisit>> clinicVisits(
    String studentId, {
    int limit = 20,
  }) async {
    final rows = await _db
        .from('clinic_visits')
        .select()
        .eq('student_id', studentId)
        .order('visited_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((m) => ClinicVisit.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  @override
  Future<DayMenu?> menuFor(DateTime date) async {
    final d = date.toIso8601String().substring(0, 10);
    final row = await _db
        .from('menus')
        .select()
        .eq('menu_date', d)
        .maybeSingle();
    return row == null ? null : DayMenu.fromMap(row);
  }

  @override
  Future<List<SchoolEvent>> upcomingEvents({int limit = 10}) async {
    final rows = await _db
        .from('events')
        .select()
        .gte('starts_at', DateTime.now().toIso8601String())
        .order('starts_at')
        .limit(limit);
    return (rows as List)
        .map((m) => SchoolEvent.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  @override
  Future<List<SchoolDocument>> documents(String studentId) async {
    final rows = await _db
        .from('documents')
        .select()
        .or('student_id.is.null,student_id.eq.$studentId')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((m) => SchoolDocument.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  @override
  Future<List<Notice>> notices(String guardianUserId, {int limit = 20}) async {
    final rows = await _db
        .from('notices')
        .select()
        .eq('recipient_id', guardianUserId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((m) => Notice.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  @override
  Future<void> markNoticeRead(String noticeId) =>
      _db.from('notices').update({'read': true}).eq('id', noticeId);
}
