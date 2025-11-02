import 'package:intl/intl.dart';

/// Extensions útiles para DateTime
extension DateTimeExtensions on DateTime {
  /// Formato dd/MM/yyyy
  String get formatted => DateFormat('dd/MM/yyyy').format(this);

  /// Formato personalizado
  String format(String pattern) => DateFormat(pattern).format(this);

  /// Formato de hora HH:mm
  String get timeFormatted {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Formato completo en español
  String get fullSpanish {
    return DateFormat('EEEE, d MMMM yyyy', 'es').format(this);
  }

  /// Verificar si es hoy
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Verificar si es ayer
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Verificar si es mañana
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Obtener inicio del día (00:00:00)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Obtener fin del día (23:59:59)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59);
  }

  /// Obtener inicio de la semana (lunes)
  DateTime get startOfWeek {
    return subtract(Duration(days: weekday - 1)).startOfDay;
  }

  /// Obtener fin de la semana (domingo)
  DateTime get endOfWeek {
    return add(Duration(days: 7 - weekday)).endOfDay;
  }

  /// Obtener inicio del mes
  DateTime get startOfMonth {
    return DateTime(year, month, 1);
  }

  /// Obtener fin del mes
  DateTime get endOfMonth {
    return DateTime(year, month + 1, 0, 23, 59, 59);
  }

  /// Formato relativo (hace 5 minutos, ayer, etc.)
  String get relative {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'Hace ${difference.inSeconds} segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (isYesterday) {
      return 'Ayer a las $timeFormatted';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else {
      return formatted;
    }
  }

  /// Agregar días laborales (sin contar sábados y domingos)
  DateTime addBusinessDays(int days) {
    var result = this;
    var addedDays = 0;

    while (addedDays < days) {
      result = result.add(const Duration(days: 1));
      if (result.weekday != DateTime.saturday &&
          result.weekday != DateTime.sunday) {
        addedDays++;
      }
    }

    return result;
  }

  /// Verificar si es día laboral
  bool get isBusinessDay {
    return weekday != DateTime.saturday && weekday != DateTime.sunday;
  }

  /// Verificar si es fin de semana
  bool get isWeekend => !isBusinessDay;
}

/// Extensions para String de fechas
extension DateStringExtensions on String {
  /// Parsear fecha en formato ISO
  DateTime? get toDateTime {
    try {
      return DateTime.parse(this);
    } catch (e) {
      return null;
    }
  }

  /// Parsear y formatear fecha
  String? formatDate([String pattern = 'dd/MM/yyyy']) {
    final date = toDateTime;
    if (date == null) return null;
    return DateFormat(pattern).format(date);
  }
}
