import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../models/event.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../utils/initials_helper.dart';

class EventCreationViewModel extends ChangeNotifier {
  final EventService _eventService = EventService();
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;

  // Form fields
  String title = '';
  DateTime? dateTime; // Start time or time
  DateTime? endDateTime;
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
            hideBottomControls: true,
            lockAspectRatio: true,
            aspectRatioPresets: [CropAspectRatioPreset.square],
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
    final currentUser = await AuthService().currentUser();
    if (currentUser == null) {
      throw Exception("User not logged in");
    }

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
        startDate: dateTime!,
        endDate: endDateTime,
        location: geoPoint,
        visibility: visibility,
        description: description.isNotEmpty ? description : null,
        image: image,
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
