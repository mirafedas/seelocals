/// Build-time configuration, passed with
/// `--dart-define-from-file=env/<flavor>.json`.
enum AppFlavor { dev, prod }

abstract final class Env {
  static const String _flavor = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static final AppFlavor flavor = AppFlavor.values.byName(_flavor);

  static bool get isDev => flavor == AppFlavor.dev;

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
}
