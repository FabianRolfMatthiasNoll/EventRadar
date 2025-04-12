import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  String? id; // Unique Firestore document ID, unknown until document creation
  final String title;
  final DateTime startDate;
  final DateTime? endDate;
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
    required this.startDate,
    this.endDate,
    required this.location,
    required this.visibility,
    this.description,
    required this.image,
    required this.creatorId,
    required this.promoted,
    this.participantCount = 0,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'title': title,
      'date': startDate, // Named Date because if no Enddate is selected this represents the date of the event.
      'location': location,
      'visibility': visibility,
      'description': description,
      'image': image,
      'createdAt': DateTime.now(),
      'creatorId': creatorId,
      'promoted': promoted,
      'participantCount': participantCount,
    };
    if (endDate != null) {
      map['endDate'] = endDate;
    }
    return map;
  }

  factory Event.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      startDate: data['date']?.toDate() ?? DateTime.now(),
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
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
