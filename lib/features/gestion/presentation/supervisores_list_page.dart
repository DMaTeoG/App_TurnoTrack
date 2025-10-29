import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../data/supervisores_repo.dart';
import '../domain/supervisor.dart';

final supervisoresListProvider = FutureProvider.autoDispose
    .family<List<SupervisorModel>, String>((ref, filtro) async {
      return ref.watch(supervisoresRepositoryProvider).listar(filtro: filtro);
    });

class SupervisoresListPage extends ConsumerStatefulWidget {
  const SupervisoresListPage({super.key});

  @override
  ConsumerState<SupervisoresListPage> createState() =>
      _SupervisoresListPageState();
}

class _SupervisoresListPageState extends ConsumerState<SupervisoresListPage> {
  final _searchController = TextEditingController();
  String _filtro = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supervisoresAsync = ref.watch(supervisoresListProvider(_filtro));

    return AppScaffold(
      title: const Text('Supervisores'),
      actions: [
        IconButton(
          onPressed: () => context.go('/gestion/supervisores/nuevo'),
          icon: const Icon(Icons.add),
          tooltip: 'Nuevo supervisor',
        ),
      ],
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
            child: supervisoresAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.supervisor_account_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text('Sin supervisores registrados.'),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final supervisor = items[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.supervisor_account_outlined),
                        title: Text(supervisor.nombre),
                        subtitle: Text(supervisor.documento),
                        trailing: Icon(
                          supervisor.activo
                              ? Icons.check_circle
                              : Icons.pause_circle,
                          color: supervisor.activo
                              ? Colors.green
                              : Colors.orange,
                        ),
                        onTap: () => context.go(
                          '/gestion/supervisores/${supervisor.id}',
                        ),
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
