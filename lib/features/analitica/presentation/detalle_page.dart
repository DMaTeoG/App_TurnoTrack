import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/analytics_repo.dart';

final detalleRegistrosProvider = FutureProvider.autoDispose
    .family<List<DetalleRegistro>, DateTimeRange>((ref, rango) {
  return ref.watch(analyticsRepositoryProvider).detalleRegistros(
        desde: rango.start,
        hasta: rango.end,
      );
});

class DetallePage extends ConsumerStatefulWidget {
  const DetallePage({super.key});

  @override
  ConsumerState<DetallePage> createState() => _DetallePageState();
}

class _DetallePageState extends ConsumerState<DetallePage> {
  late DateTimeRange _rango;
  bool _exportando = false;
  String? _mensaje;

  @override
  void initState() {
    super.initState();
    final ahora = DateTime.now();
    _rango = DateTimeRange(
      start: ahora.subtract(const Duration(days: 7)),
      end: ahora,
    );
  }

  Future<void> _seleccionarRango() async {
    final nuevoRango = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 180)),
      lastDate: DateTime.now(),
      initialDateRange: _rango,
    );
    if (nuevoRango != null) {
      setState(() {
        _rango = DateTimeRange(
          start: DateTime(nuevoRango.start.year, nuevoRango.start.month,
              nuevoRango.start.day, 0, 0),
          end: DateTime(nuevoRango.end.year, nuevoRango.end.month,
              nuevoRango.end.day, 23, 59, 59),
        );
      });
    }
  }

  Future<void> _exportarCsv() async {
    setState(() {
      _exportando = true;
      _mensaje = null;
    });

    final url = await ref.read(analyticsRepositoryProvider).exportCsv(
          desde: _rango.start,
          hasta: _rango.end,
        );

    if (!mounted) return;

    setState(() {
      _exportando = false;
      _mensaje = url == null
          ? 'No se pudo generar el CSV.'
          : 'Export listo. URL firmada: $url';
    });
  }

  @override
  Widget build(BuildContext context) {
    final registrosAsync = ref.watch(detalleRegistrosProvider(_rango));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle y exportacion'),
        actions: [
          IconButton(
            onPressed: _exportando ? null : _exportarCsv,
            icon: _exportando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            tooltip: 'Exportar CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Desde ${_rango.start.toLocal().toIso8601String().split('T').first} '
                    'hasta ${_rango.end.toLocal().toIso8601String().split('T').first}',
                  ),
                ),
                TextButton.icon(
                  onPressed: _seleccionarRango,
                  icon: const Icon(Icons.date_range),
                  label: const Text('Cambiar'),
                ),
              ],
            ),
          ),
          if (_mensaje != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _mensaje!,
                style: const TextStyle(color: Colors.green),
              ),
            ),
          Expanded(
            child: registrosAsync.when(
              data: (registros) {
                if (registros.isEmpty) {
                  return const Center(child: Text('Sin registros en el periodo.'));
                }
                return ListView.separated(
                  itemCount: registros.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (context, index) {
                    final reg = registros[index];
                    return ListTile(
                      leading: const Icon(Icons.timer_outlined),
                      title: Text(reg.empleado),
                      subtitle: Text(
                        '${reg.fecha.toLocal()} • Supervisor: ${reg.supervisor ?? 'N/A'}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${reg.horas.toStringAsFixed(1)} h'),
                          Text('Incidencias: ${reg.incidencias}'),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
