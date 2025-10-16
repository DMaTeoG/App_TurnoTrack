import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/desempeno_repo.dart';

final rankingProvider = FutureProvider.autoDispose((ref) {
  final semana = DateTime.now();
  return ref.watch(desempenoRepositoryProvider).rankingSemanal(semana: semana);
});

class RankingPage extends ConsumerWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(rankingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking semanal'),
        actions: [
          IconButton(
            onPressed: () => context.go('/desempeno/mis-consejos'),
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Mis consejos',
          ),
        ],
      ),
      body: rankingAsync.when(
        data: (ranking) {
          if (ranking.isEmpty) {
            return const Center(child: Text('Sin datos para la semana actual.'));
          }
          return ListView.separated(
            itemCount: ranking.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final item = ranking[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text(item.empleado),
                subtitle: Text('Supervisor: ${item.supervisor ?? 'N/A'}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Score: ${item.score.toStringAsFixed(1)}'),
                    Text('Puntualidad: ${(item.puntualidad).toStringAsFixed(0)}%'),
                    Text('Horas: ${item.horas.toStringAsFixed(1)}'),
                  ],
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
