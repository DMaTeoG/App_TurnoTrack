import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_client_provider.dart';
import '../data/desempeno_repo.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Mis consejos IA')),
      body: consejosAsync.when(
        data: (consejos) {
          if (consejos.isEmpty) {
            return const Center(
              child: Text('Aun no tienes consejos generados para esta semana.'),
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
