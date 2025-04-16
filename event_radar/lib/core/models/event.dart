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
  final List<String> participants;

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
    required this.participants,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'title': title,
      'date': startDate,
      'location': location,
      'visibility': visibility,
      'description': description,
      'image': image,
      'createdAt': DateTime.now(),
      'creatorId': creatorId,
      'promoted': promoted,
      'participantCount': participantCount,
      'participants': participants,
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
      participants: (data['participants'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ??
          [data['creatorId'] ?? 'dummyUserId'],
    );
  }
}
