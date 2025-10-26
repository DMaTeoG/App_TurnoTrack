class AppConstants {
  static const supabaseUrl =
      String.fromEnvironment('https://ixfdivaywaixpqcpednr.supabase.co', defaultValue: '');
  static const supabaseAnonKey =
      String.fromEnvironment('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4ZmRpdmF5d2FpeHBxY3BlZG5yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0NDQ4NjcsImV4cCI6MjA3NzAyMDg2N30.c_CKH5aCNjz38_eKNGf4zIzdlVALeXg7MBXMWHlj2HE', defaultValue: '');

  static const registrosBucket = 'registros';
  static const exportsBucket = 'exports';

  static const gpsAccuracyThresholdMeters = 10.0;
  static const photoRetentionMonths = 24;

  static const coachingMaxTips = 3;
}

