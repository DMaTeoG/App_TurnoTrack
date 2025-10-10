import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/empleados_repo.dart';
import '../../domain/empleado.dart';

final empleadoPickerProvider = FutureProvider.autoDispose
    .family<List<EmpleadoModel>, String>((ref, filtro) async {
  return ref.watch(empleadosRepositoryProvider).listar(filtro: filtro);
});

class EmpleadoPicker extends ConsumerStatefulWidget {
  const EmpleadoPicker({
    super.key,
    required this.onSelected,
  });

  final ValueChanged<EmpleadoModel> onSelected;

  @override
  ConsumerState<EmpleadoPicker> createState() => _EmpleadoPickerState();
}

class _EmpleadoPickerState extends ConsumerState<EmpleadoPicker> {
  String _filtro = '';

  @override
  Widget build(BuildContext context) {
    final empleadosAsync = ref.watch(empleadoPickerProvider(_filtro));

    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Buscar empleado',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _filtro = value),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: empleadosAsync.when(
            data: (empleados) => ListView.builder(
              itemCount: empleados.length,
              itemBuilder: (context, index) {
                final empleado = empleados[index];
                return ListTile(
                  title: Text(empleado.nombre),
                  subtitle: Text(empleado.documento),
                  onTap: () => widget.onSelected(empleado),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }
}
