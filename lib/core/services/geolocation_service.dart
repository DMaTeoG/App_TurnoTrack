import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class GeolocationService {
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return null;
      }

      if (permission == LocationPermission.denied) {
        return null;
      }

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        await Geolocator.openLocationSettings();
        return null;
      }

      return Geolocator.getCurrentPosition(desiredAccuracy: accuracy);
    } on LocationServiceDisabledException catch (error) {
      debugPrint('Location service disabled: $error');
      return null;
    } on PermissionDefinitionsNotFoundException catch (error) {
      debugPrint('Location permission missing in manifest: $error');
      return null;
    } catch (error) {
      debugPrint('Unexpected location error: $error');
      return null;
    }
  }

  Future<double?> distanceBetween(Position a, Position b) async {
    try {
      final distance = Geolocator.distanceBetween(
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      );
      return distance;
    } catch (error) {
      debugPrint('Error calculating distance: $error');
      return null;
    }
  }
}

final geolocationServiceProvider = Provider<GeolocationService>((ref) {
  return GeolocationService();
});
