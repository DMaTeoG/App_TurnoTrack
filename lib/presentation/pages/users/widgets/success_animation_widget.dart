import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget de animación de éxito al crear/editar usuario
///
/// Muestra:
/// - Checkmark animado
/// - Confetti particles
/// - Mensaje de éxito
/// - Auto-dismiss después de 3 segundos
class SuccessAnimationWidget extends StatefulWidget {
  const SuccessAnimationWidget({
    super.key,
    required this.userName,
    required this.isEditing,
  });

  final String userName;
  final bool isEditing;

  @override
  State<SuccessAnimationWidget> createState() => _SuccessAnimationWidgetState();
}

class _SuccessAnimationWidgetState extends State<SuccessAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _checkmarkController;
  late AnimationController _confettiController;
  late AnimationController _fadeController;

  late Animation<double> _checkmarkScaleAnimation;
  late Animation<double> _checkmarkRotationAnimation;
  late Animation<double> _fadeAnimation;

  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _generateParticles();
    _startAnimations();
  }

  void _setupAnimations() {
    // Animación del checkmark
    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _checkmarkScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkmarkController, curve: Curves.elasticOut),
    );

    _checkmarkRotationAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(parent: _checkmarkController, curve: Curves.easeOutBack),
    );

    // Animación del confetti
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animación de fade in/out
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);
  }

  void _generateParticles() {
    final random = Random();
    for (int i = 0; i < 40; i++) {
      _particles.add(
        _ConfettiParticle(
          x: random.nextDouble(),
          y: random.nextDouble() * 0.3,
          color: _getRandomColor(),
          size: random.nextDouble() * 6 + 4,
          rotation: random.nextDouble() * 360,
          velocity: random.nextDouble() * 2 + 1,
        ),
      );
    }
  }

  Color _getRandomColor() {
    final colors = [
      AppTheme.primaryBlue,
      AppTheme.secondaryBlue,
      AppTheme.accentBlue,
      Colors.amber,
      Colors.pink,
      Colors.purple,
      Colors.green,
    ];
    return colors[Random().nextInt(colors.length)];
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      _checkmarkController.forward();
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      _confettiController.forward();
    });
  }

  @override
  void dispose() {
    _checkmarkController.dispose();
    _confettiController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Stack(
          children: [
            // Confetti particles
            ...List.generate(_particles.length, (index) {
              final particle = _particles[index];
              return AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) {
                  final progress = _confettiController.value;
                  final screenSize = MediaQuery.of(context).size;

                  return Positioned(
                    left: screenSize.width * particle.x,
                    top:
                        screenSize.height *
                        (particle.y + (progress * particle.velocity * 0.8)),
                    child: Transform.rotate(
                      angle: particle.rotation * progress * 4,
                      child: Opacity(
                        opacity: 1 - progress,
                        child: Container(
                          width: particle.size,
                          height: particle.size,
                          decoration: BoxDecoration(
                            color: particle.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Contenido central
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Checkmark animado
                  AnimatedBuilder(
                    animation: _checkmarkController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _checkmarkScaleAnimation.value,
                        child: Transform.rotate(
                          angle: _checkmarkRotationAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 80,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Mensaje de éxito
                  Text(
                    widget.isEditing
                        ? '¡Usuario Actualizado!'
                        : '¡Usuario Creado!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Nombre del usuario
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                    ),
                    child: Text(
                      widget.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Mensaje adicional
                  Text(
                    widget.isEditing
                        ? 'Los cambios han sido guardados exitosamente'
                        : 'El usuario puede acceder al sistema ahora',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double rotation;
  final double velocity;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.rotation,
    required this.velocity,
  });
}
