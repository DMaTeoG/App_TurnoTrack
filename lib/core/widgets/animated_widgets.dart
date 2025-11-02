import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Smooth animated page transition similar to Apple Music / App Store
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  SmoothPageRoute({
    required this.page,
    this.duration = AppTheme.normalAnimation,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // Slide + Fade transition
           const begin = Offset(0.0, 0.05);
           const end = Offset.zero;
           final tween = Tween(
             begin: begin,
             end: end,
           ).chain(CurveTween(curve: AppTheme.smoothCurve));
           final offsetAnimation = animation.drive(tween);

           final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
             CurvedAnimation(parent: animation, curve: AppTheme.defaultCurve),
           );

           return SlideTransition(
             position: offsetAnimation,
             child: FadeTransition(opacity: fadeAnimation, child: child),
           );
         },
       );
}

/// Hero-like transition for cards expanding to full screen
class CardExpandRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Rect? originRect;

  CardExpandRoute({required this.page, this.originRect})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: AppTheme.slowAnimation,
        reverseTransitionDuration: AppTheme.slowAnimation,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: AppTheme.bounceCurve,
          );

          return ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      );
}

/// Animated container with shimmer effect for loading states
class ShimmerContainer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerContainer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerContainer> createState() => _ShimmerContainerState();
}

class _ShimmerContainerState extends State<ShimmerContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius:
                widget.borderRadius ??
                BorderRadius.circular(AppTheme.radiusMedium),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
            ),
          ),
        );
      },
    );
  }
}

/// Animated list item that slides in with fade
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration? delay;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppTheme.normalAnimation,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: AppTheme.defaultCurve),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppTheme.defaultCurve),
    );

    // Stagger animation based on index
    Future.delayed(
      widget.delay ?? Duration(milliseconds: 50 * widget.index),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}

/// Bouncy animated button with scale effect
class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Duration duration;

  const BouncyButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.duration = AppTheme.fastAnimation,
  });

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: AppTheme.bounceCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

/// Animated floating action button with rotation and scale
class AnimatedFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;

  const AnimatedFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppTheme.normalAnimation,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: AppTheme.bounceCurve),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: AppTheme.bounceCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
      widget.onPressed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fab = FloatingActionButton(
      onPressed: _handleTap,
      child: RotationTransition(
        turns: _rotationAnimation,
        child: Icon(widget.icon),
      ),
    );

    if (widget.label != null) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: _handleTap,
          icon: RotationTransition(
            turns: _rotationAnimation,
            child: Icon(widget.icon),
          ),
          label: Text(widget.label!),
        ),
      );
    }

    return ScaleTransition(scale: _scaleAnimation, child: fab);
  }
}

/// Skeleton loader for cards - Apple Music style
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerContainer(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(20),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerContainer(
                        width: double.infinity,
                        height: 16,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      ShimmerContainer(
                        width: 150,
                        height: 12,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            ShimmerContainer(
              width: double.infinity,
              height: 100,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress indicator with smooth animation
class SmoothProgressIndicator extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;

  const SmoothProgressIndicator({
    super.key,
    required this.value,
    this.color,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: AppTheme.normalAnimation,
      curve: AppTheme.smoothCurve,
      tween: Tween<double>(begin: 0, end: value),
      builder: (context, animatedValue, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: animatedValue,
            minHeight: height,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppTheme.primaryBlue,
            ),
          ),
        );
      },
    );
  }
}
