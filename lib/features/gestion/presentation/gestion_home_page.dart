import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_scaffold.dart';

class GestionHomePage extends StatelessWidget {
  const GestionHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showDock: true,
      title: const Text('Gestion de personal'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Empleados'),
              subtitle: const Text('Crear, editar y asignar supervisores'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/gestion/empleados'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.supervisor_account_outlined),
              title: const Text('Supervisores'),
              subtitle: const Text('Gestionar responsables de equipo'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/gestion/supervisores'),
            ),
          ),
        ],
      ),
    );
  }
}
