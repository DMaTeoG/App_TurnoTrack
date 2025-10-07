import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/empleados_repo.dart';
import '../data/supervisores_repo.dart';
import '../domain/empleado.dart';
import '../domain/supervisor.dart';

final empleadoDetalleProvider = FutureProvider.autoDispose
    .family<EmpleadoModel?, String>((ref, id) async {
  try {
    final lista = await ref.watch(empleadosRepositoryProvider).listar();
    return lista.firstWhere((item) => item.id == id);
  } catch (_) {
    return null;
  }
});

final supervisoresComboProvider = FutureProvider.autoDispose<List<SupervisorModel>>(
  (ref) => ref.watch(supervisoresRepositoryProvider).listar(),
);

class EmpleadoFormPage extends ConsumerStatefulWidget {
  const EmpleadoFormPage({super.key, this.empleadoId});

  final String? empleadoId;

  @override
  ConsumerState<EmpleadoFormPage> createState() => _EmpleadoFormPageState();
}

class _EmpleadoFormPageState extends ConsumerState<EmpleadoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _documentoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  String _rol = 'operador';
  String? _supervisorId;
  bool _activo = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.empleadoId != null) {
      Future.microtask(() async {
        final empleado =
            await ref.read(empleadoDetalleProvider(widget.empleadoId!).future);
        if (!mounted || empleado == null) return;
        setState(() {
          _documentoController.text = empleado.documento;
          _nombreController.text = empleado.nombre;
          _emailController.text = empleado.email ?? '';
          _telefonoController.text = empleado.telefono ?? '';
          _rol = empleado.rol;
          _supervisorId = empleado.supervisorId;
          _activo = empleado.activo;
        });
      });
    }
  }

  @override
  void dispose() {
    _documentoController.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    final empleado = EmpleadoModel(
      id: widget.empleadoId ?? const Uuid().v4(),
      documento: _documentoController.text.trim(),
      nombre: _nombreController.text.trim(),
      rol: _rol,
      supervisorId: _supervisorId,
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      telefono: _telefonoController.text.trim().isEmpty
          ? null
          : _telefonoController.text.trim(),
      activo: _activo,
    );

    await ref.read(empleadosRepositoryProvider).guardar(empleado);

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final supervisoresAsync = ref.watch(supervisoresComboProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.empleadoId == null ? 'Nuevo empleado' : 'Editar empleado',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _documentoController,
                decoration: const InputDecoration(labelText: 'Documento'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _rol,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(value: 'operador', child: Text('Operador')),
                  DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) => setState(() => _rol = value ?? 'operador'),
              ),
              const SizedBox(height: 12),
              supervisoresAsync.when(
                data: (supervisores) => DropdownButtonFormField<String?>(
                  // ignore: deprecated_member_use
                  value: _supervisorId,
                  decoration: const InputDecoration(labelText: 'Supervisor'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Sin asignar')),
                    for (final supervisor in supervisores)
                      DropdownMenuItem(
                        value: supervisor.id,
                        child: Text(supervisor.nombre),
                      ),
                  ],
                  onChanged: (value) => setState(() => _supervisorId = value),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => Text('Error: $error'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Telefono'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _activo,
                onChanged: (value) => setState(() => _activo = value),
                title: const Text('Activo'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _guardar,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

