import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/config/constants.dart';
import '../../../core/services/camera_service.dart';
import '../../../core/services/geolocation_service.dart';

class CapturaPage extends ConsumerStatefulWidget {
  const CapturaPage({super.key});

  @override
  ConsumerState<CapturaPage> createState() => _CapturaPageState();
}

class _CapturaPageState extends ConsumerState<CapturaPage> {
  XFile? _foto;
  Position? _posicion;
  bool _loadingFoto = false;
  bool _loadingGps = false;
  String? _error;

  Future<void> _obtenerPosicion() async {
    setState(() {
      _loadingGps = true;
      _error = null;
    });

    final geo = ref.read(geolocationServiceProvider);
    final position = await geo.getCurrentPosition();

    if (!mounted) return;

    setState(() {
      _posicion = position;
      _loadingGps = false;
      if (position == null) {
        _error = 'No fue posible obtener ubicacion. Revisa permisos.';
      }
    });
  }

  Future<void> _capturarFoto() async {
    setState(() {
      _loadingFoto = true;
      _error = null;
    });

    final camera = ref.read(cameraServiceProvider);
    final foto = await camera.captureSelfie();

    if (!mounted) return;

    setState(() {
      _foto = foto;
      _loadingFoto = false;
      if (foto == null) {
        _error = 'No fue posible capturar foto.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final precision = _posicion?.accuracy;
    final precisionOk = precision != null &&
        precision <= AppConstants.gpsAccuracyThresholdMeters;

    return Scaffold(
      appBar: AppBar(title: const Text('Captura de evidencia')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Precision requerida: <= ${AppConstants.gpsAccuracyThresholdMeters} m',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: SizedBox(
                height: 200,
                child: Center(
                  child: _foto != null
                      ? Text('Foto capturada: ${_foto!.name}')
                      : const Text('Sin foto'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadingFoto ? null : _capturarFoto,
                    icon: const Icon(Icons.photo_camera_front),
                    label: _loadingFoto
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Capturar foto'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadingGps ? null : _obtenerPosicion,
                    icon: const Icon(Icons.my_location),
                    label: _loadingGps
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Actualizar GPS'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_posicion != null)
              ListTile(
                leading: Icon(
                  precisionOk ? Icons.check_circle : Icons.error_outline,
                  color: precisionOk ? Colors.green : Colors.orange,
                ),
                title: Text(
                  'Lat: ${_posicion!.latitude.toStringAsFixed(5)}, Lng: ${_posicion!.longitude.toStringAsFixed(5)}',
                ),
                subtitle: Text('Precision: ${precision?.toStringAsFixed(1)} m'),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: (_foto != null && precisionOk)
                  ? () => Navigator.of(context).pop({'foto': _foto, 'posicion': _posicion})
                  : null,
              child: const Text('Usar captura'),
            ),
          ],
        ),
      ),
    );
  }
}

