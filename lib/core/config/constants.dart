import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const _supabaseUrlEnv = String.fromEnvironment('SUPABASE_URL');
  static const _supabaseAnonKeyEnv = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseUrl =>
      _supabaseUrlEnv.isNotEmpty ? _supabaseUrlEnv : dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey => _supabaseAnonKeyEnv.isNotEmpty
      ? _supabaseAnonKeyEnv
      : dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static const registrosBucket = 'registros';
  static const exportsBucket = 'exports';

  static const gpsAccuracyThresholdMeters = 10.0;
  static const photoRetentionMonths = 24;

  static const coachingMaxTips = 3;
}
