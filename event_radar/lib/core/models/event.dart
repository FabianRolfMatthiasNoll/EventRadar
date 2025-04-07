import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  String? id; // Unique Firestore document ID, unknown until document creation
  final String title;
  final DateTime date;
  final GeoPoint location;
  final String visibility;
  final String? description;
  final String image;
  final String creatorId;
  final bool promoted;
  final int participantCount;

  Event({
    this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.visibility,
    this.description,
    required this.image,
    required this.creatorId,
    required this.promoted,
    this.participantCount = 0,
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
      'participantCount': participantCount,
    };
  }

  factory Event.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      date: data['date']?.toDate() ?? DateTime.now(),
      location: data['location'],
      visibility: data['visibility'] ?? 'public',
      description: data['description'],
      image: data['image'] ?? '',
      creatorId: data['creatorId'] ?? 'dummyUserId',
      promoted: data['promoted'] ?? false,
      participantCount: data['participantCount'] ?? 0,
    );
  }
}
