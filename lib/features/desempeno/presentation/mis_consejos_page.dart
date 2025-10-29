import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../data/desempeno_repo.dart';
import '../../../core/providers/supabase_client_provider.dart';

final consejosProvider = FutureProvider.autoDispose((ref) async {
  final session = ref.watch(currentSessionProvider);
  final empleadoId = session?.user.id;
  if (empleadoId == null) {
    return <ConsejoIA>[];
  }
  return ref
      .watch(desempenoRepositoryProvider)
      .consejosUsuario(empleadoId: empleadoId);
});

class MisConsejosPage extends ConsumerWidget {
  const MisConsejosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consejosAsync = ref.watch(consejosProvider);

    return AppScaffold(
      title: const Text('Mis consejos IA'),
      body: consejosAsync.when(
        data: (consejos) {
          if (consejos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Aun no tienes consejos generados para esta semana.'),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: consejos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final consejo = consejos[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semana ${consejo.semana}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(consejo.mensajeEs),
                      if (consejo.mensajeEn != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          consejo.mensajeEn!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
