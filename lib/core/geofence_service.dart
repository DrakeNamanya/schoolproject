import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/staff.dart';

/// A position sample relative to the campus geofence.
class FenceSample {
  final double lat, lng;
  final double accuracyM;
  final double distanceM;
  final bool inside;
  final DateTime at;
  final bool simulated;

  const FenceSample({
    required this.lat,
    required this.lng,
    required this.accuracyM,
    required this.distanceM,
    required this.inside,
    required this.at,
    this.simulated = false,
  });
}

/// Streams position samples and classifies them against the active fence.
///
/// * On Android with location permission: real GPS via `geolocator`.
/// * On web / when permission is denied: a **simulation** stream that keeps
///   the device inside the fence, plus `runDemoTrip()` which plays the
///   leave-and-re-enter sequence from the design prototype.
///
/// Privacy rule (Uganda Data Protection & Privacy Act 2019): callers must
/// only start the stream inside the staff member's duty window.
class GeofenceService {
  GeofenceService(this.fence);

  final Geofence fence;
  final _ctrl = StreamController<FenceSample>.broadcast();
  StreamSubscription<Position>? _gps;
  Timer? _sim;
  bool _simulating = false;
  double _simOffsetM = 40; // how far from centre the simulated pin sits
  final double _simBearing = 0.7;

  Stream<FenceSample> get samples => _ctrl.stream;
  bool get isSimulating => _simulating;

  Future<void> start() async {
    if (kIsWeb) return _startSim();
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever ||
          !await Geolocator.isLocationServiceEnabled()) {
        return _startSim();
      }
      _gps = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        (p) => _ctrl.add(_classify(p.latitude, p.longitude, p.accuracy, false)),
        onError: (_) => _startSim(),
      );
    } catch (_) {
      _startSim();
    }
  }

  void _startSim() {
    _simulating = true;
    _sim?.cancel();
    _emitSim();
    _sim = Timer.periodic(const Duration(seconds: 4), (_) => _emitSim());
  }

  void _emitSim() {
    // tiny jitter so the pin breathes
    final jitter = (math.Random().nextDouble() - .5) * 4;
    final (lat, lng) = _offset(fence.lat, fence.lng, _simOffsetM + jitter, _simBearing);
    _ctrl.add(_classify(lat, lng, 6, true));
  }

  /// Demo: walk out of the fence, linger, walk back in. Returns when done.
  Future<void> runDemoTrip() async {
    if (!_simulating) return;
    _sim?.cancel();
    Future<void> step(double m, [int ms = 500]) async {
      _simOffsetM = m;
      _emitSim();
      await Future.delayed(Duration(milliseconds: ms));
    }
    for (final m in [70.0, 100.0, 125.0, 160.0, 220.0, 260.0]) {
      await step(m);
    }
    await Future.delayed(const Duration(milliseconds: 1400));
    for (final m in [200.0, 150.0, 110.0, 80.0, 50.0, 40.0]) {
      await step(m);
    }
    _sim = Timer.periodic(const Duration(seconds: 4), (_) => _emitSim());
  }

  FenceSample _classify(double lat, double lng, double acc, bool sim) {
    final d = distanceMeters(fence.lat, fence.lng, lat, lng);
    return FenceSample(
      lat: lat,
      lng: lng,
      accuracyM: acc,
      distanceM: d,
      inside: d <= fence.radiusM,
      at: DateTime.now(),
      simulated: sim,
    );
  }

  Future<void> stop() async {
    await _gps?.cancel();
    _sim?.cancel();
  }

  void dispose() {
    stop();
    _ctrl.close();
  }

  // ---- geo maths --------------------------------------------------------

  static double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1), dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static (double, double) _offset(double lat, double lng, double meters, double bearing) {
    const r = 6371000.0;
    final d = meters / r;
    final la1 = _rad(lat), lo1 = _rad(lng);
    final la2 = math.asin(math.sin(la1) * math.cos(d) + math.cos(la1) * math.sin(d) * math.cos(bearing));
    final lo2 = lo1 + math.atan2(math.sin(bearing) * math.sin(d) * math.cos(la1), math.cos(d) - math.sin(la1) * math.sin(la2));
    return (la2 * 180 / math.pi, lo2 * 180 / math.pi);
  }

  static double _rad(double deg) => deg * math.pi / 180;
}
