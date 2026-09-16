import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/user.dart';
import 'config.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// Session + role state for the whole app.
///
/// In DEMO mode (no Supabase credentials) it signs in a fixed set of demo
/// accounts so every shell can be previewed. With Supabase configured it
/// wraps `supabase.auth` and loads roles from `v_me`.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    if (AppConfig.hasSupabase) {
      _client = sb.Supabase.instance.client;
      _client!.auth.onAuthStateChange.listen((_) => _refresh());
      _refresh();
    } else {
      _status = AuthStatus.signedOut;
    }
  }

  sb.SupabaseClient? _client;
  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  UserRole? _activeRole;
  String? _error;
  bool _busy = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  UserRole? get activeRole => _activeRole;
  String? get error => _error;
  bool get busy => _busy;
  bool get isDemo => !AppConfig.hasSupabase;

  /// Which shell to show. Null when a role picker is needed.
  AppShell? get shell => _activeRole?.shell;

  bool get needsRolePicker =>
      _user != null && _activeRole == null && _user!.roles.length > 1;

  // ------------------------------------------------------------------
  // Demo accounts (mirrors the design prototype personas)
  // ------------------------------------------------------------------
  static const demoAccounts = <String, AppUser>{
    'parent': AppUser(
      id: 'demo-parent',
      fullName: 'Mukisa Josephine',
      title: 'Ms.',
      phone: '+256 772 894 001',
      roles: [UserRole.parent],
    ),
    'teacher': AppUser(
      id: 'demo-teacher',
      fullName: 'Ssekandi Brian',
      title: 'Mr.',
      roles: [UserRole.teacher, UserRole.parent],
    ),
    'bursar': AppUser(
      id: 'demo-bursar',
      fullName: 'Nsubuga Joseph',
      roles: [UserRole.bursar],
    ),
    'nurse': AppUser(
      id: 'demo-nurse',
      fullName: 'Alice Namusoke',
      title: 'Nurse',
      roles: [UserRole.nurse],
    ),
    'director': AppUser(
      id: 'demo-director',
      fullName: 'Kato Robert',
      title: 'Dr.',
      roles: [UserRole.director, UserRole.admin],
    ),
  };

  Future<void> signInDemo(String key) async {
    final u = demoAccounts[key];
    if (u == null) return;
    _user = u;
    _activeRole = u.roles.length == 1 ? u.roles.first : null;
    _status = AuthStatus.signedIn;
    _error = null;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Supabase auth
  // ------------------------------------------------------------------
  Future<void> signInWithPassword(String identifier, String password) async {
    if (isDemo) {
      // Accept any of the demo keys as the identifier.
      final key = identifier.trim().toLowerCase();
      if (demoAccounts.containsKey(key)) return signInDemo(key);
      _error = 'Demo mode: use one of the demo accounts below.';
      notifyListeners();
      return;
    }
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final isPhone = RegExp(r'^\+?\d{9,15}$').hasMatch(identifier.trim());
      if (isPhone) {
        await _client!.auth.signInWithPassword(
          phone: _normalisePhone(identifier),
          password: password,
        );
      } else {
        await _client!.auth.signInWithPassword(
          email: identifier.trim(),
          password: password,
        );
      }
      await _refresh();
    } on sb.AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Could not sign in. Check your connection and try again.';
      if (kDebugMode) debugPrint('signIn error: $e');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _refresh() async {
    final session = _client?.auth.currentSession;
    if (session == null) {
      _user = null;
      _activeRole = null;
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    try {
      final row = await _client!.from('v_me').select().single();
      _user = AppUser.fromMap(row);
      _activeRole = _user!.roles.length == 1 ? _user!.roles.first : null;
      _status = AuthStatus.signedIn;
    } catch (e) {
      if (kDebugMode) debugPrint('profile load error: $e');
      _user = AppUser(
        id: session.user.id,
        fullName: session.user.email ?? 'User',
        roles: const [UserRole.parent],
      );
      _activeRole = UserRole.parent;
      _status = AuthStatus.signedIn;
    }
    notifyListeners();
  }

  void chooseRole(UserRole r) {
    if (_user == null || !_user!.has(r)) return;
    _activeRole = r;
    notifyListeners();
  }

  void switchRole() {
    if ((_user?.roles.length ?? 0) > 1) {
      _activeRole = null;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (!isDemo) await _client?.auth.signOut();
    _user = null;
    _activeRole = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  static String _normalisePhone(String raw) {
    var p = raw.replaceAll(RegExp(r'[\s\-()]'), '');
    if (p.startsWith('0')) p = '+256${p.substring(1)}';
    if (!p.startsWith('+')) p = '+$p';
    return p;
  }
}
