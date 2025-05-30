import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  List<String> _missingFields() {
    final List<String> missing = [];
    if (title.isEmpty) missing.add('Titel');
    if (dateTime == null) missing.add('Startdatum');
    if (location == null) missing.add('Ort');
    return missing;
  }

  String _buildErrorMessage(List<String> fields) {
    if (fields.isEmpty) return '';
    if (fields.length == 1) return 'Bitte ${fields.first} angeben.';
    final last = fields.removeLast();
    final joined = fields.join(', ');
    return 'Bitte $joined und $last angeben.';
  }

  Future<String> createEvent() async {
    final currentUser = AuthService().currentUser();
    if (currentUser == null) {
      throw Exception("User not logged in");
    }

    final missing = _missingFields();
    if (missing.isNotEmpty) {
      return _buildErrorMessage(List.from(missing));
    }

    isLoading = true;
    notifyListeners();

    try {
      final geoPoint = GeoPoint(location!.latitude, location!.longitude);

      // Berechnen des Ablaufdatum: 30 Tage nach endDate (oder nach startDate, falls kein endDate)
      final baseDate = endDateTime ?? dateTime!;
      final expiryDate = Timestamp.fromDate(
        baseDate.add(const Duration(days: 30)),
      );

      final event = Event(
        title: title,
        startDate: dateTime!,
        endDate: endDateTime,
        expiryDate: expiryDate,
        location: geoPoint,
        visibility: visibility,
        description: description.isNotEmpty ? description : null,
        image: imageUrl ?? '',
        creatorId: currentUser.uid,
        promoted: promoted,
        participantCount: 1,
        participants: [currentUser.uid],
      );

      final createdEvent = await _eventService.createEvent(
        event,
        imageFile: imageFile,
      );

      await FirebaseMessaging.instance.subscribeToTopic(
        'event_${createdEvent.id}_announcements',
      );

      return 'Event erfolgreich erstellt';
    } catch (e) {
      return 'Fehler beim Erstellen des Events: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
