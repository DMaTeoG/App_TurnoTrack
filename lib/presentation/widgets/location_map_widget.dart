import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  LocationModel? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _checkCurrentLocation();
  }

  /// Verificar si la ubicación actual coincide con alguna permitida
  void _checkCurrentLocation() {
    for (final location in widget.allowedLocations) {
      // Validación EXACTA (sin radio)
      if (location.latitude == widget.currentLatitude &&
          location.longitude == widget.currentLongitude) {
        setState(() {
          _selectedLocation = location;
        });
        widget.onLocationSelected?.call(location);
        return;
      }
    }
    // Si no coincide exactamente, no hay ubicación válida
    widget.onLocationSelected?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPosition = LatLng(
      widget.currentLatitude,
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
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentPosition,
              initialZoom: 16.0,
              minZoom: 12.0,
              maxZoom: 18.0,
            ),
            children: [
              // Tiles de OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                                  color: Colors.black.withValues(alpha: 0.3),
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
                    width: 50,
                    height: 50,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
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
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Info de ubicación actual (overlay)
          Positioned(
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
                _mapController.move(currentPosition, 16.0);
              },
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
