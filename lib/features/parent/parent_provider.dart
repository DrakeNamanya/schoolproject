import 'package:flutter/foundation.dart';

import '../../data/parent_repository.dart';
import '../../models/academics.dart';
import '../../models/clinic.dart';
import '../../models/fees.dart';
import '../../models/school.dart';
import '../../models/student.dart';

/// Loads and caches everything the parent shell shows for the guardian's
/// children. All data is read-only here; it is produced by other roles.
class ParentProvider extends ChangeNotifier {
  ParentProvider(this._repo, this.guardianId);

  final ParentRepository _repo;
  final String guardianId;

  bool _loading = true;
  String? _error;
  List<Student> _children = const [];
  int _selected = 0;
  Term? _term;

  final Map<String, StudentSummary> _summaries = {};
  final Map<String, FeeStatement> _fees = {};
  final Map<String, ReportCard?> _reports = {};
  final Map<String, List<ClinicVisit>> _clinic = {};
  final Map<String, List<SchoolDocument>> _docs = {};
  List<PaymentChannel> _channels = const [];
  DayMenu? _todayMenu;
  List<SchoolEvent> _events = const [];
  List<Notice> _notices = const [];

  bool get loading => _loading;
  String? get error => _error;
  List<Student> get children => _children;
  int get selectedIndex => _selected;
  Student? get child => _children.isEmpty ? null : _children[_selected];
  Term? get term => _term;

  StudentSummary? get summary => child == null ? null : _summaries[child!.id];
  StudentSummary? summaryFor(String studentId) => _summaries[studentId];
  FeeStatement? get fees => child == null ? null : _fees[child!.id];
  ReportCard? get report => child == null ? null : _reports[child!.id];
  List<ClinicVisit> get clinicVisits =>
      child == null ? const [] : (_clinic[child!.id] ?? const []);
  List<SchoolDocument> get documents =>
      child == null ? const [] : (_docs[child!.id] ?? const []);
  List<PaymentChannel> get channels => _channels;
  DayMenu? get todayMenu => _todayMenu;
  List<SchoolEvent> get events => _events;
  List<Notice> get notices => _notices;
  int get unreadCount => _notices.where((n) => !n.read).length;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.myChildren(guardianId),
        _repo.currentTerm(),
        _repo.paymentChannels(),
        _repo.menuFor(DateTime.now()),
        _repo.upcomingEvents(),
        _repo.notices(guardianId),
      ]);
      _children = results[0] as List<Student>;
      _term = results[1] as Term;
      _channels = results[2] as List<PaymentChannel>;
      _todayMenu = results[3] as DayMenu?;
      _events = results[4] as List<SchoolEvent>;
      _notices = results[5] as List<Notice>;
      if (_selected >= _children.length) _selected = 0;
      await Future.wait(_children.map(_loadChild));
    } catch (e) {
      _error = 'Could not load your dashboard. Pull down to retry.';
      if (kDebugMode) debugPrint('ParentProvider.load: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadChild(Student s) async {
    final termId = _term!.id;
    final r = await Future.wait([
      _repo.summary(s.id),
      _repo.feeStatement(s.id, termId),
      _repo.latestPublishedReport(s.id),
      _repo.clinicVisits(s.id),
      _repo.documents(s.id),
    ]);
    _summaries[s.id] = r[0] as StudentSummary;
    _fees[s.id] = r[1] as FeeStatement;
    _reports[s.id] = r[2] as ReportCard?;
    _clinic[s.id] = r[3] as List<ClinicVisit>;
    _docs[s.id] = r[4] as List<SchoolDocument>;
  }

  void selectChild(int i) {
    if (i < 0 || i >= _children.length || i == _selected) return;
    _selected = i;
    notifyListeners();
  }

  Future<void> markRead(Notice n) async {
    if (n.read) return;
    await _repo.markNoticeRead(n.id);
    _notices = _notices
        .map(
          (x) => x.id == n.id
              ? Notice(
                  id: x.id,
                  kind: x.kind,
                  title: x.title,
                  subtitle: x.subtitle,
                  at: x.at,
                  amount: x.amount,
                  read: true,
                  studentId: x.studentId,
                )
              : x,
        )
        .toList();
    notifyListeners();
  }
}
