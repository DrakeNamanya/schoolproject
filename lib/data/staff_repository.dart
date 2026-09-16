import '../models/staff.dart';

/// Data access for the Staff shell (teachers + non-teaching staff).
///
/// Reads:  staff_profiles, geofences, staff_attendance_events, timetable_slots,
///         teaching_assignments, assessments, marks, students, timesheets, staff_alerts
/// Writes: staff_attendance_events, assessments, marks, attendance (roll call),
///         staff_alerts.read, staff_profiles.auto_checkin
abstract class StaffRepository {
  Future<StaffProfile> profile(String userId);
  Future<void> setAutoCheckin(String userId, bool on);

  // Geofence attendance
  Future<Geofence> activeGeofence();
  Future<List<AttendanceEvent>> todayEvents(String userId);
  Future<AttendanceEvent> recordEvent(
    String userId,
    AttendanceKind kind, {
    double? lat,
    double? lng,
    double? accuracyM,
    double? distanceM,
  });

  // Schedule
  Future<List<TimetableSlot>> slotsFor(String userId, int weekday);

  // Classes
  Future<List<TeachingAssignment>> assignments(String userId);
  Future<List<Assessment>> assessments(String assignmentId);
  Future<Assessment> createAssessment(
    String assignmentId, {
    required String title,
    required int outOf,
    required DateTime assessedOn,
  });
  Future<List<MarkEntry>> marks(String assessmentId);
  Future<void> saveMarks(String assessmentId, List<MarkEntry> entries, String enteredBy);

  // Roll call (class teacher only)
  Future<List<RollCallEntry>> rollCall(String classId, DateTime date);
  Future<void> saveRollCall(String classId, DateTime date, List<RollCallEntry> entries, String markedBy);

  // Timesheet
  Future<List<TimesheetDay>> thisWeek(String userId);
  Future<List<WeekSummary>> previousWeeks(String userId, {int count = 3});

  // Alerts
  Future<List<StaffAlert>> alerts(String userId);
  Future<void> markAlertRead(String alertId);
}
