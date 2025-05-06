import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;

  Position? get currentPosition => _currentPosition;

  Future<void> updateLocation() async {
    try {
      // Check the current permission status.
      LocationPermission permission = await Geolocator.checkPermission();

      // If permission is denied, request it.
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // If permissions are still not granted or are denied forever, use a default position.
      if (permission == LocationPermission.deniedForever ||
          (permission != LocationPermission.whileInUse &&
              permission != LocationPermission.always)) {
        _currentPosition = Position(
          latitude: 52.5200,
          longitude: 13.4050,
          timestamp: DateTime.now(),
          accuracy: 1.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      } else {
        // If permission is granted, get the current position.
        _currentPosition = await Geolocator.getCurrentPosition();
      }
    } catch (e) {
      // In case of an error, also default
      _currentPosition = Position(
        latitude: 52.5200,
        longitude: 13.4050,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
    notifyListeners();
  }
}
