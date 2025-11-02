import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'presentation/pages/splash/splash_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/check_in_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/reports_screen.dart';
import 'presentation/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientación
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializar Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Inicializar SharedPreferences (reemplaza LocalStorage/Hive)
  final prefs = await SharedPreferences.getInstance();

  // Inicializar servicio de notificaciones
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    ProviderScope(
      child: MyApp(prefs: prefs, notificationService: notificationService),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final SharedPreferences prefs;
  final NotificationService notificationService;

  const MyApp({
    super.key,
    required this.prefs,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: SplashScreen(
        onAnimationComplete: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/check-in': (context) => const CheckInScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/reports': (context) => const ReportsScreen(),
      },
    );
  }
}
