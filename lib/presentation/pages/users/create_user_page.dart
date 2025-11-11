import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../providers/auth_provider.dart';
import 'widgets/user_form_widget.dart';
import 'widgets/success_animation_widget.dart';

/// Página principal para crear usuarios (workers)
///
/// Flujo:
/// 1. Formulario con validación en tiempo real
/// 2. Photo picker (cámara/galería)
/// 3. Asignación de supervisor
/// 4. Confirmación animada con confetti
class CreateUserPage extends ConsumerStatefulWidget {
  const CreateUserPage({super.key, this.userId});

  /// ID del usuario a editar (null si es creación)
  final String? userId;

  @override
  ConsumerState<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends ConsumerState<CreateUserPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;

  bool _showSuccessAnimation = false;
  String? _createdUserName;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _headerController = AnimationController(
      duration: AppTheme.normalAnimation,
      vsync: this,
    );

    _headerSlideAnimation = Tween<double>(begin: -50, end: 0).animate(
      CurvedAnimation(parent: _headerController, curve: AppTheme.smoothCurve),
    );

    _headerFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeIn));

    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  void _onUserCreated(String userName) {
    setState(() {
      _showSuccessAnimation = true;
      _createdUserName = userName;
    });

    // Volver después de 2 segundos y refrescar lista
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(
          context,
        ).pop(true); // Retorna true para indicar éxito y refrescar
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.userId != null;
    final currentUser = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Contenido principal
          CustomScrollView(
            slivers: [
              // App Bar personalizado con animación
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.primaryBlue,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                  title: AnimatedBuilder(
                    animation: _headerController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _headerSlideAnimation.value),
                        child: Opacity(
                          opacity: _headerFadeAnimation.value,
                          child: Text(
                            isEditing ? 'Editar Usuario' : 'Nuevo Usuario',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
                      ),
                    ),
                  ),
                ),
              ),

              // Formulario
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: AnimatedListItem(
                    index: 0,
                    child: UserFormWidget(
                      userId: widget.userId,
                      currentUserRole: currentUser?.role,
                      onSuccess: _onUserCreated,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Animación de éxito superpuesta
          if (_showSuccessAnimation)
            SuccessAnimationWidget(
              userName: _createdUserName ?? 'Usuario',
              isEditing: isEditing,
            ),
        ],
      ),
    );
  }
}
