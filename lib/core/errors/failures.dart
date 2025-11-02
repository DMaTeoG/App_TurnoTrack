/// Clase base para errores/fallos en la aplicación
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

/// Error de red/conectividad
class NetworkFailure extends Failure {
  const NetworkFailure([String? message])
    : super(message ?? 'Sin conexión a internet. Verifica tu red.');
}

/// Error del servidor
class ServerFailure extends Failure {
  const ServerFailure([String? message])
    : super(message ?? 'Error del servidor. Intenta más tarde.');
}

/// Error de cache/almacenamiento local
class CacheFailure extends Failure {
  const CacheFailure([String? message])
    : super(message ?? 'Error al acceder al almacenamiento local.');
}

/// Error de autenticación
class AuthFailure extends Failure {
  const AuthFailure([String? message])
    : super(message ?? 'Error de autenticación. Verifica tus credenciales.');
}

/// Error de ubicación
class LocationFailure extends Failure {
  const LocationFailure([String? message])
    : super(message ?? 'No se pudo obtener la ubicación.');
}

/// Error de cámara
class CameraFailure extends Failure {
  const CameraFailure([String? message])
    : super(message ?? 'Error al acceder a la cámara.');
}

/// Error de permisos
class PermissionFailure extends Failure {
  const PermissionFailure([String? message])
    : super(message ?? 'Permiso denegado. Habilita los permisos en ajustes.');
}

/// Error de validación
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Error genérico
class UnknownFailure extends Failure {
  const UnknownFailure([String? message])
    : super(message ?? 'Ha ocurrido un error inesperado.');
}

/// Excepciones personalizadas
class AppException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(this.message, [this.originalError, this.stackTrace]);

  @override
  String toString() => message;
}

/// Excepción de distancia inválida
class InvalidDistanceException extends AppException {
  const InvalidDistanceException()
    : super('Estás fuera del área permitida para registrar asistencia');
}

/// Excepción de foto inválida
class InvalidPhotoException extends AppException {
  const InvalidPhotoException([String? message])
    : super(message ?? 'La foto no es válida');
}

/// Excepción de usuario no autenticado
class UnauthorizedException extends AppException {
  const UnauthorizedException()
    : super('No estás autenticado. Por favor inicia sesión.');
}

/// Excepción de permiso insuficiente
class InsufficientPermissionException extends AppException {
  const InsufficientPermissionException()
    : super('No tienes permisos suficientes para realizar esta acción.');
}
