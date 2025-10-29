import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// A visually-dense card with optional gradient header to create "sections"
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.minHeight,
    this.padding = const EdgeInsets.all(16),
    this.elevation = 2,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final double? minHeight;
  final EdgeInsets padding;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final grads = Theme.of(context).extension<AppGradients>();
    final headerGradient = grads?.accentGradient;

    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight ?? 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: headerGradient,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title!,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
