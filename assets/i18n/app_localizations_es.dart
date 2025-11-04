// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'TurnoTrack';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String homeWelcome(String name) {
    return 'Hola $name';
  }

  @override
  String get registroEntrada => 'Registrar entrada';

  @override
  String get registroSalida => 'Registrar salida';

  @override
  String get gestionTitle => 'Gestión de personal';

  @override
  String get analiticaTitle => 'Analítica';

  @override
  String get desempenoTitle => 'Desempeño e IA';
}
