import '../models/academics.dart';
import '../models/admin.dart';
import '../models/clinic.dart';
import '../models/fees.dart';
import '../models/school.dart';
import '../models/student.dart';
import 'mock/demo_store.dart' show PaymentRecord;

export 'mock/demo_store.dart' show PaymentRecord;

/// Admin console data access. Each method is scoped to a sub-role by RLS on
/// the backend; the UI additionally hides modules the role cannot use.
abstract class AdminRepository {
  // ---- Dashboard / KPIs
  Future<FinanceKpis> financeKpis();
  Future<List<StaffPresence>> staffPresence();
  Future<List<Requisition>> requisitions();
  Future<List<AuditEntry>> auditLog({int limit = 50});

  // ---- Students (Registrar)
  Future<List<Student>> students();
  Future<StudentSummary> summary(String studentId);
  Future<FeeStatus> feeStatus(String studentId);
  Future<int> balance(String studentId);
  Future<void> enrolStudent(Student s, {required String guardianName, required String guardianPhone, required String byName});

  // ---- Finance (Bursar)
  Future<List<PaymentRecord>> recentPayments({int limit = 50});
  Future<Payment> postPayment(String studentId, int amount, PaymentMethod method, String? reference, {required String byName});

  // ---- Academics (DOS)
  Future<List<ReportCard>> reportCards();
  Future<void> publishReport(String reportId, {required String byName});

  // ---- Clinic (Nurse)
  Future<List<ClinicVisit>> clinicVisitsToday();
  Future<List<ClinicVisit>> referralsThisTerm();
  Future<List<MedicineStock>> medicines();
  Future<void> recordVisit(ClinicVisit v, {required String byName});

  // ---- Kitchen (Cook)
  Future<List<DayMenu?>> weekMenu(DateTime monday);
  Future<void> setMenu(DayMenu m, {required String byName});

  // ---- Events (Registrar / Director)
  Future<List<SchoolEvent>> events();
  Future<void> addEvent(SchoolEvent e, {required String byName});

  // ---- Procurement / Stores (Bursar)
  Future<void> setRequisitionStatus(String id, RequisitionStatus s, {required String byName});
  Future<List<StockItem>> stock();
}
