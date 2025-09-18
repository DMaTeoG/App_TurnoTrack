class AppConstants {
  static const supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static const registrosBucket = 'registros';
  static const exportsBucket = 'exports';

  static const gpsAccuracyThresholdMeters = 10.0;
  static const photoRetentionMonths = 24;

  static const coachingMaxTips = 3;
}

