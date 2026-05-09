// lib/services/location_permission_service.dart
//
// Kapselt alle Berechtigungsabfragen für GPS (Vordergrund + Hintergrund).

import 'package:geolocator/geolocator.dart';

enum LocationPermissionState {
  granted,
  deniedOnce,
  deniedForever,
  serviceDisabled,
}

class LocationPermissionService {
  /// Fragt alle nötigen Berechtigungen an und gibt den resultierenden Status zurück.
  Future<LocationPermissionState> requestPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionState.serviceDisabled;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionState.deniedForever;
    }

    if (permission == LocationPermission.denied) {
      return LocationPermissionState.deniedOnce;
    }

    // whileInUse reicht für Vordergrund; für Background muss der User
    // in den Einstellungen „Immer erlauben" wählen.
    return LocationPermissionState.granted;
  }

  Future<bool> hasPermission() async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.always ||
        p == LocationPermission.whileInUse;
  }

  Future<void> openSettings() => Geolocator.openAppSettings();
}
