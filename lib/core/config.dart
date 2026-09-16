/// Runtime configuration. Values are injected at build time so no secrets
/// live in source control:
///
///   flutter build web --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///                     --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// When both are empty the app runs in DEMO mode against seeded in-memory
/// data, which is what the web preview uses until the Supabase project is
/// wired up.
class AppConfig {
  AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Firebase is used ONLY for push alerts (FCM). It is initialised when the
  /// platform config (google-services.json / firebase_options) is present.
  static const enablePush = bool.fromEnvironment(
    'ENABLE_PUSH',
    defaultValue: false,
  );

  static const schoolName = 'Timbitwire Girls School';
  static const schoolShort = 'Timbitwire';
  static const motto = 'Do More To Become More';
  static const vendor = 'Data Collectors Ltd';
}
