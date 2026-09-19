import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/staff.dart';
import '../staff_repository.dart';

/// Staff shell against Supabase. Tables/RPCs: 0002_staff.sql + 0004.
class SupabaseStaffRepository implements StaffRepository {
  SupabaseStaffRepository(this._db);
  final SupabaseClient _db;

  Map<String, dynamic> _m(dynamic r) => Map<String, dynamic>.from(r as Map);

  @override
  Future<StaffProfile> profile(String userId) async {
    final row = await _db.from('staff_profiles').select().eq('user_id', userId).maybeSingle();
    if (row == null) {
      return StaffProfile(userId: userId, staffNo: '—', dutyStart: '07:30', dutyEnd: '17:00', weeklyTargetMinutes: 2400);
    }
    return StaffProfile.fromMap(row);
  }

  @override
  Future<void> setAutoCheckin(String userId, bool on) =>
      _db.from('staff_profiles').update({'auto_checkin': on}).eq('user_id', userId);

  @override
  Future<Geofence> activeGeofence() async {
    final row = await _db.from('geofences').select().eq('active', true).limit(1).single();
    return Geofence.fromMap(row);
  }

  @override
  Future<List<AttendanceEvent>> todayEvents(String userId) async {
    final start = DateTime.now();
    final midnight = DateTime(start.year, start.month, start.day).toUtc().toIso8601String();
    final rows = await _db
        .from('staff_attendance_events')
        .select()
        .eq('staff_id', userId)
        .gte('at', midnight)
        .order('at', ascending: false);
    return (rows as List).map((r) => AttendanceEvent.fromMap(_m(r))).toList();
  }

  @override
  Future<AttendanceEvent> recordEvent(String userId, AttendanceKind kind, {double? lat, double? lng, double? accuracyM, double? distanceM}) async {
    final fence = await _db.from('geofences').select('id').eq('active', true).limit(1).single();
    final row = await _db.from('staff_attendance_events').insert({
      'staff_id': userId,
      'geofence_id': fence['id'],
      'kind': kind.key,
      'at': DateTime.now().toUtc().toIso8601String(),
      'lat': lat,
      'lng': lng,
      'accuracy_m': accuracyM,
      'distance_m': distanceM,
    }).select().single();
    return AttendanceEvent.fromMap(row);
  }

  @override
  Future<List<TimetableSlot>> slotsFor(String userId, int weekday) async {
    final rows = await _db.from('v_timetable').select().eq('teacher_id', userId).eq('weekday', weekday).order('starts_at');
    return (rows as List).map((r) {
      final m = _m(r);
      final title = (m['title'] as String?)?.isNotEmpty == true
          ? m['title'] as String
          : '${m['subject_name'] ?? ''} · ${m['class_name'] ?? ''}';
      return TimetableSlot(
        id: m['id'] as String,
        weekday: (m['weekday'] as num).toInt(),
        startsAt: (m['starts_at'] as String).substring(0, 5),
        endsAt: (m['ends_at'] as String).substring(0, 5),
        title: title,
        room: m['room'] as String?,
        classSize: m['class_id'] == null ? null : (m['class_size'] as num?)?.toInt(),
      );
    }).toList();
  }

  @override
  Future<List<TeachingAssignment>> assignments(String userId) async {
    final rows = await _db.from('v_teaching_assignments').select().eq('teacher_id', userId).order('class_name');
    return (rows as List).map((r) {
      final m = _m(r);
      return TeachingAssignment(
        id: m['id'] as String,
        schoolClass: SchoolClass(
          id: m['class_id'] as String,
          name: m['class_name'] as String,
          level: (m['level'] as num?)?.toInt() ?? 0,
          classTeacherId: m['class_teacher_id'] as String?,
          size: (m['class_size'] as num?)?.toInt() ?? 0,
        ),
        subject: Subject(id: m['subject_id'] as String, code: m['subject_code'] as String, name: m['subject_name'] as String),
        isClassTeacher: m['class_teacher_id'] == userId,
      );
    }).toList();
  }

  @override
  Future<List<Assessment>> assessments(String assignmentId) async {
    final ta = await _db.from('teaching_assignments').select('class_id, subject_id, term_id').eq('id', assignmentId).single();
    final rows = await _db
        .from('assessments')
        .select()
        .eq('class_id', ta['class_id'])
        .eq('subject_id', ta['subject_id'])
        .eq('term_id', ta['term_id'])
        .order('assessed_on', ascending: false);
    return (rows as List).map((r) {
      final m = _m(r);
      m['assignment_id'] = assignmentId;
      return Assessment.fromMap(m);
    }).toList();
  }

  @override
  Future<Assessment> createAssessment(String assignmentId, {required String title, required int outOf, required DateTime assessedOn}) async {
    final ta = await _db.from('v_teaching_assignments').select().eq('id', assignmentId).single();
    final row = await _db.from('assessments').insert({
      'term_id': ta['term_id'],
      'class_id': ta['class_id'],
      'subject_id': ta['subject_id'],
      'class_name': ta['class_name'],
      'subject': ta['subject_name'],
      'title': title,
      'out_of': outOf,
      'assessed_on': assessedOn.toIso8601String().substring(0, 10),
      'teacher_id': _db.auth.currentUser?.id,
    }).select().single();
    final m = Map<String, dynamic>.from(row)..['assignment_id'] = assignmentId;
    return Assessment.fromMap(m);
  }

  @override
  Future<List<MarkEntry>> marks(String assessmentId) async {
    final rows = await _db.rpc('marks_grid', params: {'p_assessment': assessmentId});
    return (rows as List).map((r) {
      final m = _m(r);
      return MarkEntry(
        studentId: m['student_id'] as String,
        studentName: m['full_name'] as String,
        admissionNo: m['admission_no'] as String,
        score: (m['score'] as num?)?.toInt(),
        comment: m['comment'] as String?,
      );
    }).toList();
  }

  @override
  Future<void> saveMarks(String assessmentId, List<MarkEntry> entries, String enteredBy) async {
    final rows = entries
        .where((e) => e.score != null || (e.comment?.isNotEmpty ?? false))
        .map((e) => {
              'assessment_id': assessmentId,
              'student_id': e.studentId,
              'score': e.score,
              'comment': e.comment,
              'entered_by': enteredBy,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
        .toList();
    if (rows.isEmpty) return;
    await _db.from('marks').upsert(rows, onConflict: 'assessment_id,student_id');
  }

  @override
  Future<List<RollCallEntry>> rollCall(String classId, DateTime date) async {
    final rows = await _db.rpc('roll_call', params: {'p_class': classId, 'p_date': date.toIso8601String().substring(0, 10)});
    return (rows as List).map((r) {
      final m = _m(r);
      return RollCallEntry(
        studentId: m['student_id'] as String,
        studentName: m['full_name'] as String,
        admissionNo: m['admission_no'] as String,
        present: (m['present'] as bool?) ?? true,
      );
    }).toList();
  }

  @override
  Future<void> saveRollCall(String classId, DateTime date, List<RollCallEntry> entries, String markedBy) async {
    final term = await _db.from('terms').select('id').eq('is_current', true).limit(1).single();
    await _db.from('attendance').upsert(
      entries
          .map((e) => {
                'student_id': e.studentId,
                'term_id': term['id'],
                'on_date': date.toIso8601String().substring(0, 10),
                'present': e.present,
                'marked_by': markedBy,
              })
          .toList(),
      onConflict: 'student_id,on_date',
    );
  }

  @override
  Future<List<TimesheetDay>> thisWeek(String userId) async {
    final now = DateTime.now();
    final mon = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final rows = await _db.rpc('my_week', params: {'p_monday': mon.toIso8601String().substring(0, 10)});
    final byDate = {for (final r in rows as List) (r['on_date'] as String).substring(0, 10): TimesheetDay.fromMap(_m(r))};
    return List.generate(5, (i) {
      final d = DateTime(mon.year, mon.month, mon.day + i);
      final k = d.toIso8601String().substring(0, 10);
      return byDate[k] ??
          TimesheetDay(date: d, minutesWorked: 0, status: d.isBefore(DateTime(now.year, now.month, now.day)) ? 'absent' : 'scheduled');
    });
  }

  @override
  Future<List<WeekSummary>> previousWeeks(String userId, {int count = 3}) async {
    final rows = await _db.rpc('my_previous_weeks', params: {'p_count': count});
    return (rows as List).map((r) {
      final start = DateTime.parse(r['week_start'] as String);
      final end = start.add(const Duration(days: 4));
      final label = 'Week of ${start.day.toString().padLeft(2, '0')} ${_mon(start)} · ${start.day.toString().padLeft(2, '0')}–${end.day.toString().padLeft(2, '0')} ${_mon(end)}';
      return WeekSummary(label, (r['minutes'] as num).toInt());
    }).toList();
  }

  static String _mon(DateTime d) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1];

  @override
  Future<List<StaffAlert>> alerts(String userId) async {
    final rows = await _db.from('staff_alerts').select().eq('recipient_id', userId).order('created_at', ascending: false).limit(50);
    return (rows as List).map((r) => StaffAlert.fromMap(_m(r))).toList();
  }

  @override
  Future<void> markAlertRead(String alertId) => _db.from('staff_alerts').update({'read': true}).eq('id', alertId);
}
