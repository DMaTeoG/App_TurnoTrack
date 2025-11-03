import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import 'presentation/pages/dashboards/manager_dashboard_page.dart';
import 'presentation/pages/dashboards/supervisor_dashboard_page.dart';
import 'presentation/pages/dashboards/worker_dashboard_page.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientación
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Cargar variables de entorno desde el archivo .env
  await dotenv.load(fileName: '.env');

  // Inicializar Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Inicializar SharedPreferences
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
      home: Builder(
        builder: (navigatorContext) {
          return SplashScreen(
            onAnimationComplete: () {
              Navigator.of(navigatorContext).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          );
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/check-in': (context) => const CheckInScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/manager': (context) {
          // Obtener el usuario actual del provider
          return Consumer(
            builder: (context, ref, _) {
              final authState = ref.watch(authNotifierProvider);
              return authState.when(
                data: (user) {
                  if (user == null) {
                    // Si no hay usuario, redirigir a login
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    });
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return ManagerDashboardPage(user: user);
                },
                loading: () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) =>
                    Scaffold(body: Center(child: Text('Error: $err'))),
              );
            },
          );
        },
        '/supervisor': (context) {
          return Consumer(
            builder: (context, ref, _) {
              final authState = ref.watch(authNotifierProvider);
              return authState.when(
                data: (user) {
                  if (user == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    });
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return SupervisorDashboardPage(user: user);
                },
                loading: () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) =>
                    Scaffold(body: Center(child: Text('Error: $err'))),
              );
            },
          );
        },
        '/worker': (context) {
          return Consumer(
            builder: (context, ref, _) {
              final authState = ref.watch(authNotifierProvider);
              return authState.when(
                data: (user) {
                  if (user == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    });
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return WorkerDashboardPage(user: user);
                },
                loading: () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) =>
                    Scaffold(body: Center(child: Text('Error: $err'))),
              );
            },
          );
        },
      },
    );
  }
}
