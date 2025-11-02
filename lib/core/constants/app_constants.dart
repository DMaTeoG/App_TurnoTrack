import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Supabase Configuration (from .env)
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Gemini AI Configuration (from .env)
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // Geolocation
  static const double maxDistanceMeters = 100.0; // Distancia máxima permitida
  static const int locationAccuracyMeters = 20;

  // Photo
  static const int maxPhotoSizeKB = 2048; // 2MB
  static const int photoQuality = 85;

  // Sync
  static const Duration syncInterval = Duration(minutes: 15);
  static const int maxRetries = 3;

  // Cache
  static const Duration cacheExpiration = Duration(hours: 24);

  // Animation
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Roles
  static const String roleWorker = 'worker';
  static const String roleSupervisor = 'supervisor';
  static const String roleManager = 'manager';

  // Storage Buckets
  static const String attendancePhotosBucket = 'attendance-photos';
  static const String profilePhotosBucket = 'profile-photos';
}

class AppStrings {
  static const String appName = 'Asistión';
  static const String tagline = 'Control de Asistencia Inteligente';

  // Auth
  static const String login = 'Iniciar Sesión';
  static const String logout = 'Cerrar Sesión';
  static const String email = 'Correo Electrónico';
  static const String password = 'Contraseña';

  // Attendance
  static const String checkIn = 'Registrar Entrada';
  static const String checkOut = 'Registrar Salida';
  static const String takePhoto = 'Tomar Foto';
  static const String verifyLocation = 'Verificar Ubicación';

  // Errors
  static const String errorGeneric = 'Ha ocurrido un error. Intenta de nuevo.';
  static const String errorLocation = 'No se pudo obtener tu ubicación';
  static const String errorCamera = 'No se pudo acceder a la cámara';
  static const String errorDistance = 'Estás muy lejos del punto de registro';
  static const String errorNetwork = 'Sin conexión a Internet';

  // Success
  static const String successCheckIn = '¡Entrada registrada con éxito!';
  static const String successCheckOut = '¡Salida registrada con éxito!';
}
