import 'package:cloud_firestore/cloud_firestore.dart';

//TODO: Set up TLS index on expiry Date and publish cloud function to automatically delete events
class Event {
  String? id; // Unique Firestore document ID, unknown until document creation
  final String title;
  final DateTime startDate;
  final DateTime? endDate;
  final Timestamp expiryDate;
  final GeoPoint location;
  final String visibility;
  final String? description;
  final String image;
  final String creatorId;
  final bool promoted;
  final int participantCount;
  final List<String> participants;

  static final EventAttributes attr = EventAttributes();

  static int maxTitleLength = 50;

  Event({
    this.id,
    required this.title,
    required this.startDate,
    this.endDate,
    required this.expiryDate,
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
      attr.title: title,
      attr.startDate: startDate,
      attr.expiryDate: expiryDate,
      attr.location: location,
      attr.visibility: visibility,
      attr.description: description,
      attr.image: image,
      attr.createdAt: DateTime.now(),
      attr.creatorId: creatorId,
      attr.promoted: promoted,
      attr.participantCount: participantCount,
      attr.participants: participants,
    };
    if (endDate != null) {
      map[attr.endDate] = endDate;
    }
    return map;
  }

  factory Event.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data[attr.title] ?? '',
      startDate: data[attr.startDate]?.toDate() ?? DateTime.now(),
      expiryDate: data[attr.expiryDate] as Timestamp,
      endDate:
          data[attr.endDate] != null
              ? (data[attr.endDate] as Timestamp).toDate()
              : null,
      location: data[attr.location],
      visibility: data[attr.visibility] ?? 'public',
      description: data[attr.description],
      image: data[attr.image] ?? '',
      creatorId: data[attr.creatorId] ?? 'dummyUserId',
      promoted: data[attr.promoted] ?? false,
      participantCount: data[attr.participantCount] ?? 0,
      participants:
          (data[attr.participants] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [data[attr.creatorId] ?? 'dummyUserId'],
    );
  }
}

class EventAttributes {
  final title = 'title';
  final startDate = 'date';
  final endDate = 'endDate';
  final expiryDate = 'expiryDate';
  final location = 'location';
  final visibility = 'visibility';
  final description = 'description';
  final image = 'image';
  final createdAt = 'createdAt';
  final creatorId = 'creatorId';
  final promoted = 'promoted';
  final participantCount = 'participantCount';
  final participants = 'participants';
}
