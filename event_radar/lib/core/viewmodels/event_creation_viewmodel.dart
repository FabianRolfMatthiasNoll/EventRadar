import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../utils/initials_helper.dart';

class EventCreationViewModel extends ChangeNotifier {
  final EventService _eventService = EventService();

  bool isLoading = false;

  String title = '';
  DateTime? dateTime;
  LatLng? location; // Temporär als LatLng
  String visibility = 'public';
  String description = '';
  String? imageUrl;

  bool validate() {
    return title.isNotEmpty && dateTime != null && location != null;
  }

  Future<String> createEvent() async {
    if (!validate()) {
      return 'Bitte alle Pflichtfelder ausfüllen.';
    }
    isLoading = true;
    notifyListeners();

    try {
      // Falls kein Bild hochgeladen wurde, verwende Initialen
      final image = imageUrl ?? getInitials(title);

      // Umwandeln von LatLng zu GeoPoint
      final geoPoint = GeoPoint(location!.latitude, location!.longitude);

      final event = Event(
        title: title,
        date: dateTime!,
        location: geoPoint,
        visibility: visibility,
        description: description.isNotEmpty ? description : null,
        image: image,
      );

      await _eventService.createEvent(event);
      return 'Event erfolgreich erstellt';
    } catch (e) {
      return 'Fehler beim Erstellen des Events: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
