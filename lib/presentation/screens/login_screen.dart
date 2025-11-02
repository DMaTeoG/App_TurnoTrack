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
      await ref
          .read(authNotifierProvider.notifier)
          .signIn(_emailController.text.trim(), _passwordController.text);

      if (mounted) {
        context.showSuccess('¡Bienvenido!');
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        context.showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
