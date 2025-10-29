import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../data/analytics_repo.dart';

final heatmapProvider = FutureProvider.autoDispose((ref) {
  final dia = DateTime.now();
  return ref.watch(analyticsRepositoryProvider).heatmap(dia: dia);
});

class MapaPage extends ConsumerWidget {
  const MapaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puntosAsync = ref.watch(heatmapProvider);

    return AppScaffold(
      title: const Text('Mapa de registros'),
      body: puntosAsync.when(
        data: (puntos) {
          if (puntos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Sin datos para la fecha seleccionada.'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: puntos.length,
            itemBuilder: (context, index) {
              final punto = puntos[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text('Lat ${punto.latitud.toStringAsFixed(4)}, Lng ${punto.longitud.toStringAsFixed(4)}'),
                  subtitle: Text('Registros: ${punto.conteo}'),
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
