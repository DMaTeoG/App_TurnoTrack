import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import '../../data/models/user_model.dart';

/// Widget de mapa con OpenStreetMap
/// SIN validación de radio - solo markers en ubicaciones exactas
class LocationMapWidget extends StatefulWidget {
  final double currentLatitude;
  final double currentLongitude;
  final List<LocationModel> allowedLocations;
  final Function(LocationModel?)? onLocationSelected;
  final double height;

  const LocationMapWidget({
    super.key,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.allowedLocations,
    this.onLocationSelected,
    this.height = 300,
  });

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget> {
  final MapController _mapController = MapController();
  final GlobalKey _overlayKey = GlobalKey();
  double _displayLatOffset = 0.0006; // fallback offset in degrees (~60m)
  final double _currentZoom = 16.0;
  LocationModel? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _checkCurrentLocation();
  }

  void _computeOffsetForOverlay(double mapHeight) {
    try {
      final rb = _overlayKey.currentContext?.findRenderObject() as RenderBox?;
      final overlayHeight = rb?.size.height ?? 0.0;
      final pixelOffset = overlayHeight + 12.0;

      // Estimate meters per pixel using Web Mercator at current latitude & zoom
      final latRad = widget.currentLatitude * math.pi / 180.0;
      const double R = 6378137.0;
      final metersPerPixel =
          (math.cos(latRad) * 2.0 * math.pi * R) /
          (256.0 * math.pow(2.0, _currentZoom));

      final metersOffset = pixelOffset * metersPerPixel;
      const double metersPerDegreeLat = 111320.0;
      final degreesOffset = metersOffset / metersPerDegreeLat;

      if (degreesOffset.isFinite && degreesOffset > 0) {
        if ((degreesOffset - _displayLatOffset).abs() > 0.00001) {
          setState(() {
            _displayLatOffset = degreesOffset;
          });
        }
      }
    } catch (_) {
      // ignore measurement errors and keep fallback offset
    }
  }

  /// Verificar si la ubicación actual coincide con alguna permitida
  /// ✅ ACTUALIZADO: Acepta cualquier ubicación (sin validación restrictiva)
  void _checkCurrentLocation() {
    // Si no hay ubicaciones configuradas, aceptar cualquier ubicación
    if (widget.allowedLocations.isEmpty) {
      setState(() {
        _selectedLocation = LocationModel(
          id: 'current',
          name: 'Ubicación actual',
          latitude: widget.currentLatitude,
          longitude: widget.currentLongitude,
          isActive: true,
        );
      });
      widget.onLocationSelected?.call(_selectedLocation);
      return;
    }

    // Si hay ubicaciones configuradas, buscar la más cercana
    // Tolerancia de ~50 metros (aproximadamente 0.0005 grados)
    const double tolerance = 0.0005;

    for (final location in widget.allowedLocations) {
      final latDiff = (location.latitude - widget.currentLatitude).abs();
      final lngDiff = (location.longitude - widget.currentLongitude).abs();

      // Si está dentro de la tolerancia, aceptar
      if (latDiff <= tolerance && lngDiff <= tolerance) {
        setState(() {
          _selectedLocation = location;
        });
        widget.onLocationSelected?.call(location);
        return;
      }
    }

    // ✅ CAMBIO IMPORTANTE: Si no hay coincidencia, aceptar de todas formas
    // Esto permite check-in desde cualquier ubicación
    setState(() {
      _selectedLocation = LocationModel(
        id: 'current',
        name: 'Ubicación actual',
        latitude: widget.currentLatitude,
        longitude: widget.currentLongitude,
        isActive: true,
      );
    });
    widget.onLocationSelected?.call(_selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPosition = LatLng(
      widget.currentLatitude,
      widget.currentLongitude,
    );
    final displayCenter = LatLng(
      widget.currentLatitude + _displayLatOffset,
      widget.currentLongitude,
    );

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Mapa OpenStreetMap
          LayoutBuilder(
            builder: (context, constraints) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _computeOffsetForOverlay(constraints.maxHeight);
              });

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: displayCenter,
                  initialZoom: _currentZoom,
                  minZoom: 12.0,
                  maxZoom: 18.0,
                ),
                children: [
                  // Tiles de OpenStreetMap
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.turnotrack.app',
                    maxZoom: 19,
                  ),

                  // Markers de ubicaciones permitidas
                  MarkerLayer(
                    markers: [
                      // Markers de ubicaciones permitidas (AZUL)
                      ...widget.allowedLocations.map((location) {
                        return Marker(
                          point: LatLng(location.latitude, location.longitude),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedLocation = location;
                              });
                              widget.onLocationSelected?.call(location);
                            },
                            child: Column(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.blue,
                                  size: 40,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      // Marker de posición actual (VERDE si coincide, ROJO si no)
                      Marker(
                        point: currentPosition,
                        width: 56,
                        height: 56,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _selectedLocation != null
                                    ? Colors.green
                                    : Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          // Info de ubicación actual (overlay)
          Positioned(
            key: _overlayKey,
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: theme.cardColor.withValues(alpha: 0.95),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      _selectedLocation != null
                          ? Icons.check_circle
                          : Icons.warning,
                      color: _selectedLocation != null
                          ? Colors.green
                          : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedLocation != null
                                ? '✓ Ubicación válida'
                                : '✗ Ubicación no permitida',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _selectedLocation != null
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          if (_selectedLocation != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _selectedLocation!.name,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botón de centrar mapa
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'center_map',
              backgroundColor: theme.primaryColor,
              onPressed: () {
                // Move to the display center so the marker stays visible
                _mapController.move(
                  LatLng(
                    widget.currentLatitude + _displayLatOffset,
                    widget.currentLongitude,
                  ),
                  _currentZoom,
                );
              },
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
