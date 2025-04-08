import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../utils/initials_helper.dart';

class EventCreationViewModel extends ChangeNotifier {
  final EventService _eventService = EventService();
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;

  // Form fields
  String title = '';
  DateTime? dateTime;
  LatLng? location;
  String visibility = 'public';
  String description = '';
  bool promoted = false;

  // Image file (cropped)
  File? imageFile;
  // Fallback: if no image is chosen, we use initials from the title.
  String? imageUrl;

  bool validate() {
    return title.isNotEmpty && dateTime != null && location != null;
  }

  /// Picks an image from the gallery and launches the cropper.
  Future<void> pickAndCropImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.blueGrey,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
      );
      if (croppedFile != null) {
        imageFile = File(croppedFile.path);
        notifyListeners();
      }
    }
  }

  Future<String> createEvent() async {
    if (!validate()) {
      return 'Bitte alle Felder ausfüllen.';
    }
    isLoading = true;
    notifyListeners();

    try {
      final image = imageUrl ?? (imageFile != null ? '' : getInitials(title));
      final geoPoint = GeoPoint(location!.latitude, location!.longitude);
      final event = Event(
        title: title,
        date: dateTime!,
        location: geoPoint,
        visibility: visibility,
        description: description.isNotEmpty ? description : null,
        image: image,
        creatorId: 'dummyUserId', // TODO: insert actual user UID
        promoted: promoted,
        participantCount: 1, // Upon Creation we will always have one participant
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
