import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/geofence_service.dart';
import '../../data/staff_repository.dart';
import '../../models/staff.dart';

enum FenceState { inside, leaving, outside, reentering, unknown }

class StaffProvider extends ChangeNotifier {
  StaffProvider(this._repo, this.userId);

  final StaffRepository _repo;
  final String userId;

  bool _loading = true;
  String? _error;
  StaffProfile? _profile;
  Geofence? _fence;
  GeofenceService? _geo;
  StreamSubscription<FenceSample>? _sub;

  FenceSample? _last;
  FenceState _state = FenceState.unknown;
  bool _checkedIn = false;
  bool _demoRunning = false;
  int _consecutiveOutside = 0;

  List<AttendanceEvent> _today = const [];
  List<TimetableSlot> _slots = const [];
  int _weekday = DateTime.now().weekday;
  List<TeachingAssignment> _assignments = const [];
  List<TimesheetDay> _week = const [];
  List<WeekSummary> _history = const [];
  List<StaffAlert> _alerts = const [];

  // ---- getters ------------------------------------------------------------
  bool get loading => _loading;
  String? get error => _error;
  StaffProfile? get profile => _profile;
  Geofence? get fence => _fence;
  FenceSample? get sample => _last;
  FenceState get state => _state;
  bool get checkedIn => _checkedIn;
  bool get demoRunning => _demoRunning;
  bool get simulated => _geo?.isSimulating ?? true;
  List<AttendanceEvent> get today => _today;
  List<TimetableSlot> get slots => _slots;
  int get weekday => _weekday;
  List<TeachingAssignment> get assignments => _assignments;
  List<TimesheetDay> get week => _week;
  List<WeekSummary> get history => _history;
  List<StaffAlert> get alerts => _alerts;
  int get unreadAlerts => _alerts.where((a) => !a.read).length;

  int get weekMinutes => _week.fold(0, (a, d) => a + d.minutesWorked);
  int get weekTarget => _profile?.weeklyTargetMinutes ?? 2400;

  DateTime? get lastCheckInAt {
    for (final e in _today) {
      if (e.kind.isIn) return e.at;
    }
    return null;
  }

  // ---- lifecycle ----------------------------------------------------------
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final r = await Future.wait([
        _repo.profile(userId),
        _repo.activeGeofence(),
        _repo.todayEvents(userId),
        _repo.slotsFor(userId, _weekday),
        _repo.assignments(userId),
        _repo.thisWeek(userId),
        _repo.previousWeeks(userId),
        _repo.alerts(userId),
      ]);
      _profile = r[0] as StaffProfile;
      _fence = r[1] as Geofence;
      _today = r[2] as List<AttendanceEvent>;
      _slots = r[3] as List<TimetableSlot>;
      _assignments = r[4] as List<TeachingAssignment>;
      _week = r[5] as List<TimesheetDay>;
      _history = r[6] as List<WeekSummary>;
      _alerts = r[7] as List<StaffAlert>;
      _checkedIn = _today.isNotEmpty && _today.first.kind.isIn;
      _state = _checkedIn ? FenceState.inside : FenceState.unknown;
      await _startGeo();
    } catch (e) {
      _error = 'Could not load staff data.';
      if (kDebugMode) debugPrint('StaffProvider.load: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _startGeo() async {
    if (_fence == null) return;
    _geo?.dispose();
    _geo = GeofenceService(_fence!);
    _sub?.cancel();
    _sub = _geo!.samples.listen(_onSample);
    await _geo!.start();
  }

  void _onSample(FenceSample s) {
    _last = s;
    final auto = _profile?.autoCheckin ?? true;

    if (s.inside) {
      _consecutiveOutside = 0;
      if (!_checkedIn) {
        if (_state == FenceState.outside || _state == FenceState.reentering) {
          _state = FenceState.reentering;
          if (auto) _record(AttendanceKind.autoIn, s);
        } else if (_state == FenceState.unknown && auto) {
          _record(AttendanceKind.autoIn, s);
        }
      } else {
        _state = FenceState.inside;
      }
    } else {
      _consecutiveOutside++;
      if (_checkedIn) {
        // one sample out = "leaving"; two = confirmed exit
        if (_consecutiveOutside == 1) {
          _state = FenceState.leaving;
        } else if (auto) {
          _record(AttendanceKind.autoOut, s);
          if (_duringLesson()) _record(AttendanceKind.flaggedOffCampus, s);
        }
      } else {
        _state = FenceState.outside;
      }
    }
    notifyListeners();
  }

  bool _duringLesson() {
    final now = DateTime.now();
    return _slots.any((sl) => sl.stateAt(now) == SlotState.now && sl.classSize != null);
  }

  Future<void> _record(AttendanceKind kind, FenceSample s) async {
    final e = await _repo.recordEvent(
      userId,
      kind,
      lat: s.lat,
      lng: s.lng,
      accuracyM: s.accuracyM,
      distanceM: s.distanceM,
    );
    _today = [e, ..._today];
    if (kind.isIn) {
      _checkedIn = true;
      _state = FenceState.inside;
    } else if (kind.isOut) {
      _checkedIn = false;
      _state = FenceState.outside;
    }
    _alerts = await _repo.alerts(userId);
    _week = await _repo.thisWeek(userId);
    notifyListeners();
  }

  // ---- user actions -------------------------------------------------------
  Future<void> manualToggle() async {
    final s = _last;
    if (s == null) return;
    await _record(_checkedIn ? AttendanceKind.manualOut : AttendanceKind.manualIn, s);
  }

  Future<void> setAutoCheckin(bool on) async {
    await _repo.setAutoCheckin(userId, on);
    _profile = await _repo.profile(userId);
    notifyListeners();
  }

  Future<void> runDemoTrip() async {
    if (_demoRunning || _geo == null) return;
    _demoRunning = true;
    notifyListeners();
    await _geo!.runDemoTrip();
    _demoRunning = false;
    notifyListeners();
  }

  Future<void> selectWeekday(int wd) async {
    _weekday = wd;
    _slots = await _repo.slotsFor(userId, wd);
    notifyListeners();
  }

  Future<void> markAlertRead(StaffAlert a) async {
    if (a.read) return;
    await _repo.markAlertRead(a.id);
    _alerts = _alerts.map((x) => x.id == a.id ? x.asRead() : x).toList();
    notifyListeners();
  }

  Future<void> refreshAlerts() async {
    _alerts = await _repo.alerts(userId);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _geo?.dispose();
    super.dispose();
  }
}
