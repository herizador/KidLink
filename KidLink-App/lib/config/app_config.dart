class AppConfig {
  AppConfig._();

  static String get supabaseUrl =>
      const String.fromEnvironment('SUPABASE_URL');

  static String get supabaseAnonKey =>
      const String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get webUrgenciaUrl =>
      const String.fromEnvironment('WEB_URGENCIA_URL');
}
