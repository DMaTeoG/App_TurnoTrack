import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GestionHomePage extends StatelessWidget {
  const GestionHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion de personal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Empleados'),
            subtitle: const Text('Crear, editar y asignar supervisores'),
            onTap: () => context.go('/gestion/empleados'),
          ),
          ListTile(
            leading: const Icon(Icons.supervisor_account_outlined),
            title: const Text('Supervisores'),
            subtitle: const Text('Gestionar responsables de equipo'),
            onTap: () => context.go('/gestion/supervisores'),
          ),
        ],
      ),
    );
  }
}

