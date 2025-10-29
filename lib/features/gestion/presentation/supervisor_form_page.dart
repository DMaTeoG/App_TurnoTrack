import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/supervisores_repo.dart';
import '../domain/supervisor.dart';

final supervisorDetalleProvider = FutureProvider.autoDispose
    .family<SupervisorModel?, String>((ref, id) async {
      try {
        final lista = await ref.watch(supervisoresRepositoryProvider).listar();
        return lista.firstWhere((item) => item.id == id);
      } catch (_) {
        return null;
      }
    });

class SupervisorFormPage extends ConsumerStatefulWidget {
  const SupervisorFormPage({super.key, this.supervisorId});

  final String? supervisorId;

  @override
  ConsumerState<SupervisorFormPage> createState() => _SupervisorFormPageState();
}

class _SupervisorFormPageState extends ConsumerState<SupervisorFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _documentoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  bool _activo = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.supervisorId != null) {
      Future.microtask(() async {
        final supervisor = await ref.read(
          supervisorDetalleProvider(widget.supervisorId!).future,
        );
        if (!mounted || supervisor == null) return;
        setState(() {
          _documentoController.text = supervisor.documento;
          _nombreController.text = supervisor.nombre;
          _emailController.text = supervisor.email;
          _telefonoController.text = supervisor.telefono ?? '';
          _activo = supervisor.activo;
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

    final supervisor = SupervisorModel(
      id: widget.supervisorId ?? const Uuid().v4(),
      documento: _documentoController.text.trim(),
      nombre: _nombreController.text.trim(),
      email: _emailController.text.trim(),
      telefono: _telefonoController.text.trim().isEmpty
          ? null
          : _telefonoController.text.trim(),
      activo: _activo,
    );

    await ref.read(supervisoresRepositoryProvider).guardar(supervisor);

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: Text(
        widget.supervisorId == null ? 'Nuevo supervisor' : 'Editar supervisor',
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
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Telefono (opcional)',
                ),
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
                child: PrimaryButton(
                  label: 'Guardar',
                  isLoading: _saving,
                  onPressed: _saving ? null : _guardar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
