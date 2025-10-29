import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/supabase_client_provider.dart';
import '../../../core/providers/user_role_provider.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/primary_button.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final user = session?.user;
    final displayName =
        (user?.userMetadata?['full_name'] as String?) ??
        user?.email ??
        'Operador';
    final role = ref.watch(userRoleProvider);
    final actions = _actionsForRole(role);

    return AppScaffold(
      showDock: true,
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
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Hero gradient banner
          GradientBackground(
            height: 180,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, $displayName',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Listo para registrar o revisar datos?',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          PrimaryButton(
                            label: 'Registrar entrada',
                            onPressed: () => context.go('/registro/entrada'),
                          ),
                          const SizedBox(width: 8),
                          PrimaryButton(
                            label: 'Registrar salida',
                            onPressed: () => context.go('/registro/salida'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionCard(
              title: 'Accesos rápidos',
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
                children: [
                  for (final action in actions)
                    _HomeCard(
                      action: action,
                      onTap: () => context.go(action.route),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionCard(
              title: 'Actividad reciente',
              subtitle: 'Últimas acciones',
              minHeight: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ListTile(
                    leading: Icon(Icons.history),
                    title: Text('No hay actividad reciente'),
                    subtitle: Text(
                      'Realiza registros o revisa analítica para ver actividad aquí.',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

List<_HomeAction> _actionsForRole(UserRole role) {
  switch (role) {
    case UserRole.operador:
      return const [
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
          label: 'Capturar evidencia',
          icon: Icons.photo_camera_front,
          route: '/registro/captura',
        ),
        _HomeAction(
          label: 'Mis consejos IA',
          icon: Icons.lightbulb_outline,
          route: '/desempeno/mis-consejos',
        ),
      ];
    case UserRole.supervisor:
      return const [
        _HomeAction(
          label: 'Gestion de equipo',
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
    case UserRole.admin:
      return const [
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
          label: 'Capturar evidencia',
          icon: Icons.photo_camera_front,
          route: '/registro/captura',
        ),
        _HomeAction(label: 'Gestion', icon: Icons.group, route: '/gestion'),
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
  const _HomeCard({required this.action, required this.onTap});

  final _HomeAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  action.icon,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
      ),
    );
  }
}
