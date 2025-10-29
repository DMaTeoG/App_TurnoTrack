import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : (icon ?? const SizedBox.shrink()),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6),
          child: Text(label, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary)),
        ),
        style: ButtonStyle(
          minimumSize: MaterialStateProperty.all(const Size.fromHeight(52)),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 16)),
          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          elevation: MaterialStateProperty.resolveWith<double>((states) {
            if (states.contains(MaterialState.disabled)) return 0;
            if (states.contains(MaterialState.pressed)) return 2;
            if (states.contains(MaterialState.hovered)) return 8;
            return 6;
          }),
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            final base = theme.colorScheme.primary;
            if (states.contains(MaterialState.disabled)) return base.withOpacity(0.5);
            return base;
          }),
          overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.pressed)) return Colors.black.withOpacity(0.08);
            return null;
          }),
        ),
      ),
    );
  }
}
