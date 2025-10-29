import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/providers/connectivity_provider.dart';
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
                    SizedBox(width: 200, child: _KpiCard(
                      title: kpi.titulo,
                      value: kpi.valor.toStringAsFixed(1),
                      delta: kpi.variacion?.toDouble(),
                    )),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('No se pudieron cargar KPI: $error'),
            ),
            const SizedBox(height: 24),
            Text(
              'Horas efectivas (ultimos 30 dias)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            seriesAsync.when(
              data: (series) => SizedBox(
                height: 200,
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
                        border: Border.all(color: Colors.blueGrey.shade100),
                        borderRadius: BorderRadius.circular(8),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('No se pudieron cargar series: $error'),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    this.delta,
  });

  final String title;
  final String value;
  final double? delta;

  @override
  Widget build(BuildContext context) {
    final deltaText = delta == null
        ? null
        : '${delta! >= 0 ? '+' : ''}${delta!.toStringAsFixed(1)}%';
    final deltaColor = delta == null
        ? null
        : delta! >= 0
            ? Colors.green
            : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (deltaText != null) ...[
              const SizedBox(height: 4),
              Text(
                deltaText,
                style: TextStyle(color: deltaColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
