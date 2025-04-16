import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';

class EventListViewModel extends ChangeNotifier {
  final EventService _eventService = EventService();

  List<Event> events = [];
  bool isLoading = false;

  Stream<List<Event>> get userEventsStream {
    final user = AuthService().currentUser();
    if (user != null) {
      return _eventService.getUserEventsStream(user.uid);
    } else {
      return Stream.value([]);
    }
  }

  /// Computes the distance (in km) from the user's current position to the event.
  double computeDistance(GeoPoint eventLocation, Position? userPosition) {
    if (userPosition == null) return 0.0;
    return Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      eventLocation.latitude,
      eventLocation.longitude,
    ) / 1000.0;
  }
}
