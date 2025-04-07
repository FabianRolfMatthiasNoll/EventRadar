import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../services/event_service.dart';

class EventListViewModel extends ChangeNotifier {
  final EventService _eventService = EventService();

  List<Event> events = [];
  bool isLoading = false;
  Position? userPosition;

  EventListViewModel() {
    fetchEvents();
    fetchUserPosition();
  }

  Future<void> fetchEvents() async {
    isLoading = true;
    notifyListeners();
    try {
      events = await _eventService.getEvents();
    } catch (e) {
      print("Error fetching events: $e");
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchUserPosition() async {
    try {
      userPosition = await Geolocator.getCurrentPosition();
      notifyListeners();
    } catch (e) {
      print("Error fetching user position: $e");
    }
  }

  /// Berechnet die Entfernung in Kilometern vom Nutzer zum Event.
  double computeDistance(GeoPoint eventLocation) {
    if (userPosition == null) return 0.0;
    return Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      eventLocation.latitude,
      eventLocation.longitude,
    ) / 1000.0;
  }
}
