// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TurnoTrack';

  @override
  String get loginTitle => 'Sign in';

  @override
  String homeWelcome(String name) {
    return 'Hello $name';
  }

  @override
  String get registroEntrada => 'Clock in';

  @override
  String get registroSalida => 'Clock out';

  @override
  String get gestionTitle => 'Staff management';

  @override
  String get analiticaTitle => 'Analytics';

  @override
  String get desempenoTitle => 'Performance & AI';
}
