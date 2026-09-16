import '../models/academics.dart';
import '../models/clinic.dart';
import '../models/fees.dart';
import '../models/school.dart';
import '../models/student.dart';

/// Read-only data access for the Parent shell.
///
/// Every method here reads data that some OTHER role wrote:
///   students / summary      -> Registrar, teachers (attendance), DOS (position)
///   fee statement           -> Bursar + payment gateway
///   report card             -> Teachers (marks), DOS/Director (publish)
///   clinic visits           -> Nurse
///   menu                    -> Kitchen
///   events / documents      -> Director / Registrar / Bursar
///   notices                 -> System triggers on all of the above
abstract class ParentRepository {
  Future<List<Student>> myChildren(String guardianUserId);
  Future<StudentSummary> summary(String studentId);
  Future<Term> currentTerm();
  Future<FeeStatement> feeStatement(String studentId, String termId);
  Future<List<PaymentChannel>> paymentChannels();
  Future<ReportCard?> latestPublishedReport(String studentId);
  Future<List<ClinicVisit>> clinicVisits(String studentId, {int limit = 20});
  Future<DayMenu?> menuFor(DateTime date);
  Future<List<SchoolEvent>> upcomingEvents({int limit = 10});
  Future<List<SchoolDocument>> documents(String studentId);
  Future<List<Notice>> notices(String guardianUserId, {int limit = 20});
  Future<void> markNoticeRead(String noticeId);
}
