import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/supabase_client_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final user = session?.user;
    final displayName = (user?.userMetadata?['full_name'] as String?) ??
        user?.email ??
        'Operador';

    final actions = [
      _HomeAction(
        label: 'Registrar entrada',
        icon: Icons.login,
        route: '/registro/entrada',
      ),
      _HomeAction(
        label: 'Registrar salida',
        icon: Icons.logout,
        route: '/registro/salida',
      ),
      _HomeAction(
        label: 'Gestion',
        icon: Icons.group,
        route: '/gestion',
      ),
      _HomeAction(
        label: 'Analitica',
        icon: Icons.analytics,
        route: '/analitica',
      ),
      _HomeAction(
        label: 'Desempeno',
        icon: Icons.emoji_events,
        route: '/desempeno',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TurnoTrack'),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(supabaseClientProvider).auth.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesion',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola $displayName',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  for (final action in actions)
                    _HomeCard(
                      action: action,
                      onTap: () => context.go(action.route),
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

class _HomeAction {
  const _HomeAction({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.action,
    required this.onTap,
  });

  final _HomeAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, size: 32),
              const SizedBox(height: 12),
              Text(
                action.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

