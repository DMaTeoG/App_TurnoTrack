import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Full-width gradient background that uses the app's primary gradient.
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    this.child,
    this.height = 220,
    this.borderRadius = 24,
  });

  final Widget? child;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final grads = Theme.of(context).extension<AppGradients>();
    final gradient =
        grads?.primaryGradient ??
        const LinearGradient(colors: [Color(0xFF0B63FF), Color(0xFF074ED1)]);

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(borderRadius),
        ),
      ),
      child: child == null
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: child,
            ),
    );
  }
}
