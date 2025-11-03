import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../constants/app_constants.dart';

class LocationService {
  Future<bool> checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position> getCurrentPosition() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      throw Exception('Permisos de ubicación denegados');
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Servicios de ubicación deshabilitados');
    }

    // Use the new settings-based API and apply a timeout to preserve the previous behavior
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).timeout(const Duration(seconds: 10));
  }

  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  bool isWithinAllowedDistance(
    Position userPosition,
    double targetLat,
    double targetLon,
  ) {
    final distance = calculateDistance(
      userPosition.latitude,
      userPosition.longitude,
      targetLat,
      targetLon,
    );

    return distance <= AppConstants.maxDistanceMeters;
  }

  Future<bool> validateLocation(double targetLat, double targetLon) async {
    try {
      final position = await getCurrentPosition();
      return isWithinAllowedDistance(position, targetLat, targetLon);
    } catch (e) {
      return false;
    }
  }
}
