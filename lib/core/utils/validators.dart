// Validadores reutilizables para formularios
class Validators {
  /// Validar email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo electrónico es requerido';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  /// Validar contraseña
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    return null;
  }

  /// Validar campo requerido
  static String? required(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  /// Validar número de teléfono
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es requerido';
    }
    final phoneRegex = RegExp(r'^\d{10}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Ingresa un número de teléfono válido (10 dígitos)';
    }
    return null;
  }

  /// Validar longitud mínima
  static String? minLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? "Este campo"} es requerido';
    }
    if (value.length < min) {
      return '${fieldName ?? "Este campo"} debe tener al menos $min caracteres';
    }
    return null;
  }

  /// Validar longitud máxima
  static String? maxLength(String? value, int max, {String? fieldName}) {
    if (value != null && value.length > max) {
      return '${fieldName ?? "Este campo"} no puede tener más de $max caracteres';
    }
    return null;
  }

  /// Validar nombre completo / nombre de usuario (resistente a entradas raras)
  /// Reglas aplicadas:
  /// - No vacío, mínimo 3 caracteres
  /// - Debe contener al menos una letra
  /// - No puede contener el carácter '@' ni urls
  /// - No permitir secuencias largas de dígitos (p. ej. '123456789')
  /// - No permitir nombre compuesto mayormente por dígitos (>50%)
  /// - Evita caracteres repetidos excesivos
  static String? name(String? value) {
    if (value == null) return 'El nombre es requerido';
    final v = value.trim();
    if (v.isEmpty) return 'El nombre es requerido';
    if (v.length < 3) return 'El nombre debe tener al menos 3 caracteres';

    // No permitir '@' o url
    if (v.contains('@') || v.contains('http://') || v.contains('https://')) {
      return 'Nombre inválido';
    }

    // Contener al menos una letra
    final letterReg = RegExp(r"[A-Za-zÁÉÍÓÚáéíóúÑñÜü]");
    if (!letterReg.hasMatch(v)) return 'El nombre debe contener letras';

    // No permitir secuencias largas de dígitos (6 o más)
    final longDigits = RegExp(r"\d{6,}");
    if (longDigits.hasMatch(v)) return 'Nombre inválido';

    // Evitar que el nombre sea mayoritariamente números
    final digits = RegExp(r"\d");
    final digitCount = digits.allMatches(v).length;
    if (digitCount / v.replaceAll(' ', '').length > 0.5) {
      return 'Nombre inválido';
    }

    // Evitar caracteres repetidos excesivos (4 o más repetidos)
    final repeated = RegExp(r"(.)\1{4,}");
    if (repeated.hasMatch(v)) return 'Nombre inválido';

    return null;
  }
}
