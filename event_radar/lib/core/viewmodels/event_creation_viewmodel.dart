import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/event.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';

class EventCreationViewModel extends ChangeNotifier {
  final EventService _eventService = EventService();

  bool isLoading = false;

  // Form fields
  String title = '';
  DateTime? dateTime;
  DateTime? endDateTime;
  LatLng? location;
  String visibility = 'public';
  String description = '';
  bool promoted = false;

  File? imageFile;
  String? imageUrl;

  bool validate() {
    return title.isNotEmpty && dateTime != null && location != null;
  }

  Future<String> createEvent() async {
    final currentUser = AuthService().currentUser();
    if (currentUser == null) {
      throw Exception("User not logged in");
    }

    if (!validate()) {
      return 'Bitte alle Felder ausfüllen.';
    }
    isLoading = true;
    notifyListeners();

    try {
      final geoPoint = GeoPoint(location!.latitude, location!.longitude);
      final event = Event(
        title: title,
        startDate: dateTime!,
        endDate: endDateTime,
        location: geoPoint,
        visibility: visibility,
        description: description.isNotEmpty ? description : null,
        image: imageUrl ?? '',
        creatorId: currentUser.uid,
        promoted: promoted,
        participantCount: 1,
        participants: [currentUser.uid],
      );

      await _eventService.createEvent(event, imageFile: imageFile);
      return 'Event erfolgreich erstellt';
    } catch (e) {
      return 'Fehler beim Erstellen des Events: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
