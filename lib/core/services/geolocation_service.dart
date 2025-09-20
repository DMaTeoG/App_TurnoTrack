import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class GeolocationService {
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        return null;
      }
    } else if (permission == LocationPermission.deniedForever) {
      return null;
    }

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      return null;
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: accuracy);
  }

  Future<double?> distanceBetween(Position a, Position b) async {
    final distance = Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
    return distance;
  }
}

final geolocationServiceProvider = Provider<GeolocationService>((ref) {
  return GeolocationService();
});

