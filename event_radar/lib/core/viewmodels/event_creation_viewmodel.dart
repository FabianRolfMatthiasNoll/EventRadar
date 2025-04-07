import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../utils/initials_helper.dart';

class EventCreationViewModel extends ChangeNotifier {
  final EventService _eventService = EventService();
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;

  // Formularfelder
  String title = '';
  DateTime? dateTime;
  LatLng? location;
  String visibility = 'public';
  String description = '';

  // Bild-Datei
  File? imageFile;
  // Fallback: Wenn kein Bild hochgeladen wurde werden die Intialien des Namens verwendet
  String? imageUrl;

  bool validate() {
    return title.isNotEmpty && dateTime != null && location != null;
  }

  Future<void> pickImage() async {
    // TODO: Expiremnt with image_croper to get good image size and quality for these small images
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      notifyListeners();
    }
  }

  Future<String> createEvent() async {
    if (!validate()) {
      return 'Bitte alle Pflichtfelder ausfüllen.';
    }
    isLoading = true;
    notifyListeners();

    try {
      // Wenn kein Bild gewählt wurde, verwende Initialen
      final image = imageUrl ?? getInitials(title);

      final geoPoint = GeoPoint(location!.latitude, location!.longitude);

      final event = Event(
        title: title,
        date: dateTime!,
        location: geoPoint,
        visibility: visibility,
        description: description.isNotEmpty ? description : null,
        image: image,
        creatorId: '', // TODO: Das muss dann die echte UID werden später
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
