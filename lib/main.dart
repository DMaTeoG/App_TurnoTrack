import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'presentation/pages/users/user_list_page.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/locale_provider.dart';
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
    // ✅ ACTUALIZADO: Watch AsyncValue del tema
    final themeModeAsync = ref.watch(themeModeProvider);

    // ✅ ACTUALIZADO: Watch AsyncValue del idioma
    final localeAsync = ref.watch(localeProvider);

    return themeModeAsync.when(
      loading: () => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stack) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: Text('Error al cargar configuración: $error')),
        ),
      ),
      data: (themeMode) {
        return localeAsync.when(
          loading: () => const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          ),
          error: (error, stack) => MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: Text('Error al cargar idioma: $error')),
            ),
          ),
          data: (locale) {
            return MaterialApp(
              title: AppStrings.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,

              // ✅ Configuración de i18n
              locale: locale,
              supportedLocales: const [
                Locale('es', ''), // Español
                Locale('en', ''), // English
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              // Fallback locale si el idioma del dispositivo no está soportado
              localeResolutionCallback: (deviceLocale, supportedLocales) {
                if (deviceLocale != null) {
                  for (var supportedLocale in supportedLocales) {
                    if (supportedLocale.languageCode ==
                        deviceLocale.languageCode) {
                      return supportedLocale;
                    }
                  }
                }
                return supportedLocales.first; // Default: Español
              },

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
                '/users': (context) {
                  return Consumer(
                    builder: (context, ref, _) {
                      final authState = ref.watch(authNotifierProvider);
                      return authState.when(
                        data: (user) {
                          if (user == null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Navigator.of(
                                context,
                              ).pushReplacementNamed('/login');
                            });
                            return const Scaffold(
                              body: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return const UserListPage();
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
                              Navigator.of(
                                context,
                              ).pushReplacementNamed('/login');
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
                              Navigator.of(
                                context,
                              ).pushReplacementNamed('/login');
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
                              Navigator.of(
                                context,
                              ).pushReplacementNamed('/login');
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
          },
        );
      },
    );
  }
}
