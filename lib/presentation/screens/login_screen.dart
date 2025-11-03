import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../core/extensions/context_extensions.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_overlay.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Intentar iniciar sesión y obtener el usuario directamente
      await ref
          .read(authNotifierProvider.notifier)
          .signIn(_emailController.text.trim(), _passwordController.text);

      if (!mounted) return;

      // Esperar a que el estado se actualice completamente
      // Usar ref.read para forzar la lectura del estado actualizado
      await Future.delayed(const Duration(milliseconds: 300));

      // Obtener el usuario del estado actualizado
      final authState = ref.read(authNotifierProvider);

      // Debug: Ver el estado completo
      debugPrint('🔐 [LOGIN] Estado Auth: ${authState.runtimeType}');
      debugPrint('🔐 [LOGIN] Has Value: ${authState.hasValue}');
      debugPrint('🔐 [LOGIN] Has Error: ${authState.hasError}');
      debugPrint('🔐 [LOGIN] Is Loading: ${authState.isLoading}');

      // ¡IMPORTANTE! Si hay error, mostrarlo inmediatamente
      if (authState.hasError) {
        final error = authState.error;
        final stackTrace = authState.stackTrace;

        debugPrint('❌❌❌ [LOGIN ERROR DETECTADO] ❌❌❌');
        debugPrint('Error: $error');
        debugPrint('StackTrace: $stackTrace');

        if (mounted) {
          // Mensaje amigable para el usuario (sin detalles técnicos)
          String userMessage = 'No se pudo completar el inicio de sesión.';

          // Detectar tipos de error y dar mensajes específicos
          final errorStr = error.toString().toLowerCase();

          if (errorStr.contains('infinite recursion') ||
              errorStr.contains('policy')) {
            userMessage =
                'Error de configuración del servidor.\n\nPor favor contacta al administrador.';
          } else if (errorStr.contains('permission') ||
              errorStr.contains('rls')) {
            userMessage =
                'No tienes permisos para acceder.\n\nContacta al administrador.';
          } else if (errorStr.contains('relation') ||
              errorStr.contains('does not exist')) {
            userMessage =
                'Error de configuración del sistema.\n\nContacta al administrador.';
          }

          context.showError(userMessage);
        }
        return;
      }
      if (authState.isLoading) {
        debugPrint('⏳ [LOGIN] Esperando más tiempo...');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final user = authState.value;

      // Debug logs detallados
      debugPrint('🔐 [LOGIN] Usuario autenticado: ${user?.email}');
      debugPrint('🔐 [LOGIN] ID: ${user?.id}');
      debugPrint('🔐 [LOGIN] Rol: ${user?.role}');
      debugPrint('🔐 [LOGIN] Nombre: ${user?.fullName}');

      if (user == null) {
        // Si aún es null, intentar refrescar manualmente
        debugPrint('⚠️ [LOGIN] Usuario null, intentando refresh...');
        await ref.read(authNotifierProvider.notifier).refreshUser();
        await Future.delayed(const Duration(milliseconds: 200));

        final refreshedState = ref.read(authNotifierProvider);

        // Verificar error después del refresh también
        if (refreshedState.hasError) {
          debugPrint('❌ [REFRESH ERROR] ${refreshedState.error}');
          if (mounted) {
            context.showError(
              '❌ Error después de refresh:\n\n${refreshedState.error}',
            );
          }
          return;
        }

        final refreshedUser = refreshedState.value;

        debugPrint(
          '🔄 [REFRESH] Usuario después de refresh: ${refreshedUser?.email}',
        );

        if (refreshedUser == null) {
          if (mounted) {
            context.showError(
              '❌ Error: No se pudo obtener datos del usuario.\n\nVerifica:\n• Tabla "users" tiene el registro\n• RLS permite SELECT\n• ID coincide con auth.users',
            );
          }
          return;
        }

        // Usar el usuario refrescado
        _navigateByRole(refreshedUser);
        return;
      }

      // Navegar con el usuario obtenido
      _navigateByRole(user);
    } catch (e) {
      debugPrint('❌ [LOGIN ERROR] $e');

      if (mounted) {
        // Mostrar error más específico
        String errorMessage = 'Error al iniciar sesión';

        if (e.toString().contains('invalid_credentials') ||
            e.toString().contains('Invalid login credentials')) {
          errorMessage =
              '❌ Credenciales inválidas\n\nVerifica:\n• Email: ${_emailController.text.trim()}\n• Contraseña correcta\n\nUsuario de prueba:\nmanager@test.com';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Error de conexión. Verifica tu internet.';
        }

        context.showError(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateByRole(dynamic user) {
    if (!mounted) return;

    // Navegar según el rol del usuario
    final role = user.role.toLowerCase();
    String routeName;
    String welcomeMessage;

    switch (role) {
      case 'manager':
        routeName = '/manager';
        welcomeMessage = '¡Bienvenido, ${user.fullName}! (Manager)';
        break;
      case 'supervisor':
        routeName = '/supervisor';
        welcomeMessage = '¡Bienvenido, ${user.fullName}! (Supervisor)';
        break;
      case 'worker':
      default:
        routeName = '/home';
        welcomeMessage = '¡Bienvenido, ${user.fullName}!';
    }

    debugPrint('🔐 [LOGIN] Navegando a: $routeName');

    context.showSuccess(welcomeMessage);

    // Usar pushReplacementNamed para navegar
    Navigator.of(context).pushReplacementNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Iniciando sesión...',
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: size.height * 0.1),

                  // Logo y título
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),

                  const SizedBox(height: 24),

                  Text(
                    AppStrings.appName,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 8),

                  Text(
                    AppStrings.tagline,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 48),

                  // Email field
                  CustomTextField(
                    controller: _emailController,
                    label: AppStrings.email,
                    hint: 'ejemplo@correo.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: Validators.email,
                  ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0),

                  const SizedBox(height: 16),

                  // Password field
                  CustomTextField(
                    controller: _passwordController,
                    label: AppStrings.password,
                    hint: 'Mínimo 6 caracteres',
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    validator: Validators.password,
                  ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2, end: 0),

                  const SizedBox(height: 32),

                  // Login button
                  CustomButton(
                    text: AppStrings.login,
                    onPressed: _handleLogin,
                    isLoading: _isLoading,
                    icon: Icons.login,
                    height: 56,
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 16),

                  // Forgot password
                  TextButton(
                    onPressed: () {
                      context.showSnackBar('Funcionalidad próximamente');
                    },
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
