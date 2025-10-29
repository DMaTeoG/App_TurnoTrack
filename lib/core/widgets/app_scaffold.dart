import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dock_nav.dart';

/// Scaffold app-bar estándar de la app con manejo consistente del botón "volver".
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.actions,
    this.body,
    this.floatingActionButton,
    this.showBackButton = true,
    this.showDock = false,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? body;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final bool showDock;

  void _handleBack(BuildContext context) {
    // Si hay un navigator que puede hacer pop, lo usamos.
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    // Si no hay historial, llevamos al home por seguridad.
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final hasBack = showBackButton && Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        leading: hasBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _handleBack(context),
                tooltip: 'Volver',
              )
            : null,
        title: title,
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showDock ? const DockNav() : null,
    );
  }
}
