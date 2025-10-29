import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../../core/widgets/section_card.dart';
import '../data/analytics_repo.dart';

final kpisProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(analyticsRepositoryProvider).obtenerKpis();
});

final seriesHorasProvider = FutureProvider.autoDispose((ref) {
  final desde = DateTime.now().subtract(const Duration(days: 30));
  return ref.watch(analyticsRepositoryProvider).seriesHoras(desde: desde);
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(kpisProvider);
    final seriesAsync = ref.watch(seriesHorasProvider);
    final connectivity = ref.watch(connectivityProvider);

    return AppScaffold(
      showDock: true,
      title: const Text('Dashboard analitico'),
      actions: [
        IconButton(
          onPressed: () => context.go('/analitica/detalle'),
          icon: const Icon(Icons.table_view),
          tooltip: 'Detalle',
        ),
        IconButton(
          onPressed: () => context.go('/analitica/mapa'),
          icon: const Icon(Icons.map_outlined),
          tooltip: 'Mapa',
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(kpisProvider);
          ref.invalidate(seriesHorasProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            connectivity.when(
              data: (status) => Text('Conexion: ${status.name}'),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const Text('Conexion: desconocida'),
            ),
            const SizedBox(height: 12),
            kpisAsync.when(
              data: (kpis) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final kpi in kpis)
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 600
                          ? 260
                          : double.infinity,
                      child: SectionCard(
                        title: kpi.titulo,
                        minHeight: 100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kpi.valor.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            if (kpi.variacion != null)
                              Text(
                                '${kpi.variacion!.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: kpi.variacion! >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('No se pudieron cargar KPI: $error'),
            ),
            const SizedBox(height: 24),
            // Replaced the following malformed block with a clean series card below
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectionCard(
                title: 'Horas efectivas',
                subtitle: 'Últimos 30 días',
                minHeight: 140,
                child: seriesAsync.when(
                  data: (series) => SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: series.length,
                      itemBuilder: (context, index) {
                        final punto = series[index];
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blueGrey.shade50),
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).cardColor,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${punto.valor.toStringAsFixed(1)} h',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${punto.fecha.month}/${punto.fecha.day}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('No se pudieron cargar series: $error'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
