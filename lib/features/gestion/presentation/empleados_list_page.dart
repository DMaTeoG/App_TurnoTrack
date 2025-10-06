import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/empleados_repo.dart';
import '../domain/empleado.dart';

final empleadosListProvider = FutureProvider.autoDispose
    .family<List<EmpleadoModel>, String>((ref, filtro) async {
  return ref.watch(empleadosRepositoryProvider).listar(filtro: filtro);
});

class EmpleadosListPage extends ConsumerStatefulWidget {
  const EmpleadosListPage({super.key});

  @override
  ConsumerState<EmpleadosListPage> createState() => _EmpleadosListPageState();
}

class _EmpleadosListPageState extends ConsumerState<EmpleadosListPage> {
  final _searchController = TextEditingController();
  String _filtro = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empleadosAsync = ref.watch(empleadosListProvider(_filtro));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Empleados'),
        actions: [
          IconButton(
            onPressed: () => context.go('/gestion/empleados/nuevo'),
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo empleado',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o documento',
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _filtro = '');
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
              onChanged: (value) => setState(() => _filtro = value),
            ),
          ),
          Expanded(
            child: empleadosAsync.when(
              data: (empleados) {
                if (empleados.isEmpty) {
                  return const Center(child: Text('Sin empleados registrados.'));
                }
                return ListView.builder(
                  itemCount: empleados.length,
                  itemBuilder: (context, index) {
                    final empleado = empleados[index];
                    return ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: Text(empleado.nombre),
                      subtitle:
                          Text('${empleado.documento} - ${empleado.rol}'),
                      trailing: Icon(
                        empleado.activo ? Icons.check_circle : Icons.pause_circle,
                        color: empleado.activo ? Colors.green : Colors.orange,
                      ),
                      onTap: () => context.go('/gestion/empleados/${empleado.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Error al cargar empleados: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


