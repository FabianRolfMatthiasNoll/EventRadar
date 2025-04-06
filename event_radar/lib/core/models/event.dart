import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String title;
  final DateTime date;
  final GeoPoint location;
  final String visibility;
  final String? description;
  final String image; // Bild-URL oder Initialen für Logos etc
  // TODO: Add User ID of creator

  Event({
    required this.title,
    required this.date,
    required this.location,
    required this.visibility,
    this.description,
    required this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'location': location,
      'visibility': visibility,
      'description': description,
      'image': image,
      'createdAt': DateTime.now(),
    };
  }
}
