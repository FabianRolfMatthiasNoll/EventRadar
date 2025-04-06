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

  String title = '';
  DateTime? dateTime;
  LatLng? location;
  String visibility = 'public';
  String description = '';

  File? imageFile;
  String? imageUrl;

  bool validate() {
    return title.isNotEmpty && dateTime != null && location != null;
  }

  Future<void> pickImage() async {
    final XFile? pickedFile =
    await _picker.pickImage(source: ImageSource.gallery);
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
      // Fallback: Falls kein Bild ausgewählt wurde, verwende Initialen aus dem Eventnamen.
      final image = imageUrl ?? getInitials(title);

      final geoPoint = GeoPoint(location!.latitude, location!.longitude);

      final event = Event(
        title: title,
        date: dateTime!,
        location: geoPoint,
        visibility: visibility,
        description: description.isNotEmpty ? description : null,
        image: image,
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
