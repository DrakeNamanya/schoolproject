import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';

/// Firebase Cloud Messaging wrapper. Firebase is used ONLY for alerts;
/// all data stays in Supabase. The device token is stored in the
/// `device_tokens` table so a Supabase Edge Function / DB webhook can fan
/// out pushes when a notice row is inserted.
///
/// Everything is a no-op until:
///   1. android/app/google-services.json is added, and
///   2. the app is built with --dart-define=ENABLE_PUSH=true
class PushService {
  PushService._();
  static final instance = PushService._();

  bool _ready = false;
  bool get isReady => _ready;

  Future<void> init() async {
    if (!AppConfig.enablePush) return;
    try {
      await Firebase.initializeApp();
      final fm = FirebaseMessaging.instance;
      await fm.requestPermission();
      FirebaseMessaging.onMessage.listen(_onForeground);
      _ready = true;
    } catch (e) {
      if (kDebugMode) debugPrint('Push init skipped: $e');
    }
  }

  /// Call after sign-in so the token is linked to the user.
  Future<void> registerToken(String userId) async {
    if (!_ready || !AppConfig.hasSupabase) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await Supabase.instance.client.from('device_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Token registration failed: $e');
    }
  }

  void _onForeground(RemoteMessage m) {
    if (kDebugMode) {
      debugPrint('Push: ${m.notification?.title} - ${m.notification?.body}');
    }
    // Foreground banner handled by the shell listening on a stream if needed.
  }
}
