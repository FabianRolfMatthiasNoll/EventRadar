import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String title;
  final DateTime date;
  final GeoPoint location;
  final String visibility;
  final String? description;
  final String image;
  final String creatorId;
  final bool promoted;

  Event({
    required this.title,
    required this.date,
    required this.location,
    required this.visibility,
    this.description,
    required this.image,
    required this.creatorId,
    required this.promoted,
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
      'creatorId': creatorId,
      'promoted': promoted,
    };
  }
}
