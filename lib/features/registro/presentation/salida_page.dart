import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/constants.dart';
import '../../../core/providers/supabase_client_provider.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../data/registros_repo.dart';
import '../domain/entities.dart';

class SalidaPage extends ConsumerStatefulWidget {
  const SalidaPage({super.key});

  @override
  ConsumerState<SalidaPage> createState() => _SalidaPageState();
}

class _SalidaPageState extends ConsumerState<SalidaPage> {
  XFile? _foto;
  Position? _posicion;
  bool _enviando = false;
  String? _error;

  Future<void> _abrirCaptura() async {
    final resultado = await context.push<Map<String, dynamic>>('/registro/captura');
    if (resultado == null) return;

    setState(() {
      _foto = resultado['foto'] as XFile?;
      _posicion = resultado['posicion'] as Position?;
    });
  }

  Future<void> _registrarSalida() async {
    if (_foto == null || _posicion == null) {
      setState(() => _error = 'Completa captura y ubicacion antes de continuar.');
      return;
    }

    if (_posicion!.accuracy > AppConstants.gpsAccuracyThresholdMeters) {
      setState(() => _error = 'La precision GPS excede el umbral permitido.');
      return;
    }

    final session = ref.read(currentSessionProvider);
    final empleadoId = session?.user.id;
    if (empleadoId == null) {
      setState(() => _error = 'Sesion invalida, vuelve a iniciar sesion.');
      return;
    }

    final registro = Registro(
      id: const Uuid().v4(),
      empleadoId: empleadoId,
      tipo: TipoRegistro.salida,
      tiempo: DateTime.now().toUtc(),
      latitud: _posicion!.latitude,
      longitud: _posicion!.longitude,
      precisionMetros: _posicion!.accuracy,
      codigoVerificacion: const Uuid().v4().substring(0, 6).toUpperCase(),
      creadoPor: session?.user.email,
    );

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await ref.read(registrosRepositoryProvider).registrar(
            registro: registro,
            foto: _foto!,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salida registrada exitosamente.')),
      );
      context.go('/home');
    } catch (_) {
      setState(() => _error = 'No se pudo registrar la salida.');
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final precision = _posicion?.accuracy;

    return AppScaffold(
      title: const Text('Registrar salida'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cierra tu turno asegurando foto y GPS dentro de rango.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _abrirCaptura,
              icon: const Icon(Icons.photo_camera_back),
              label: const Text('Capturar evidencia'),
            ),
            const SizedBox(height: 16),
            if (_foto != null)
              Text('Foto lista: ${_foto!.name}', style: Theme.of(context).textTheme.labelLarge),
            if (precision != null)
              Text('Precision GPS: ${precision.toStringAsFixed(1)} m'),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviando ? null : _registrarSalida,
                child: _enviando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Registrar salida'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

