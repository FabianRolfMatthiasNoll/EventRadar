import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';

import '../models/event.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Uploads the image to Firebase Storage and returns its download URL.
  Future<String> uploadEventImage(File imageFile) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child("event_images")
        .child("${DateTime.now().millisecondsSinceEpoch}.jpg");
    final uploadTask = storageRef.putFile(imageFile);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Creates an event document in Firestore. If an image file is provided, it uploads it.
  /// Also creates an initial participant entry for the creator.
  Future<Event> createEvent(Event event, {File? imageFile}) async {
    String imageUrl;
    if (imageFile != null) {
      imageUrl = await uploadEventImage(imageFile);
    } else {
      imageUrl = event.image; // Use fallback (e.g. initials)
    }

    // Create the event document.
    DocumentReference eventRef = await _firestore.collection('events').add({
      ...event.toMap(),
      'image': imageUrl,
    });

    // Create the participants subcollection and add the creator as an organizer.
    await eventRef.collection('participants').doc(event.creatorId).set({
      'role': 'organizer',
      'joinedAt': Timestamp.now(),
    });

    // Create the default channel.
    DocumentReference channelRef = await eventRef.collection('channels').add({
      'channelName': 'Standard Chat',
      'channelType': 'main',
      'createdAt': Timestamp.now(),
    });

    // Create the first message in the channel.
    await channelRef.collection('messages').add({
      'text': 'Event wurde erstellt',
      'type': 'update',
      'senderId': 'admin', // TODO: Hier später UserID verwenden
      'createdAt': Timestamp.now(),
      'metadata': {},
    });

    // Return an Event instance with the assigned ID.
    return Event.fromDocument(await eventRef.get());
  }

  Stream<List<Event>> getUserEventsStream(String uid) {
    return _firestore
        .collection('events')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Event.fromDocument(doc)).toList(),
        );
  }

  Future<List<Event>> getEvents() async {
    QuerySnapshot snapshot = await _firestore.collection('events').get();
    return snapshot.docs.map((doc) => Event.fromDocument(doc)).toList();
  }

  Future<List<Event>> getPublicEvents() async {
    QuerySnapshot snapshot =
        await _firestore
            .collection('events')
            .where('visibility', isEqualTo: 'public')
            .get();
    return snapshot.docs.map((doc) => Event.fromDocument(doc)).toList();
  }

  Future<Event> getEvent(String id) async {
    var doc = await _firestore.collection('events').doc(id).get();
    return Event.fromDocument(doc);
  }

  Stream<Event> getEventStream(String id) {
    return _firestore
        .collection('events')
        .doc(id)
        .snapshots()
        .map((doc) => Event.fromDocument(doc));
  }

  Future<void> joinEvent(String eventId, String userId) async {
    DocumentReference eventRef = _firestore.collection('events').doc(eventId);
    await eventRef.update({
      'participants': FieldValue.arrayUnion([userId]),
      'participantCount': FieldValue.increment(1),
    });
    await eventRef.collection('participants').doc(userId).set({
      'role': 'participant',
      'joinedAt': Timestamp.now(),
    });
  }

  Future<void> leaveEvent(String eventId, String userId) async {
    DocumentReference eventRef = _firestore.collection('events').doc(eventId);
    await eventRef.update({
      'participants': FieldValue.arrayRemove([userId]),
      'participantCount': FieldValue.increment(-1),
    });
    await eventRef.collection('participants').doc(userId).delete();
  }

  /// For this function to work there needs to be the following index on events:
  /// (visibility,date,participantCount,__name__).
  /// If the order or amount of filters are changed the index must be adjusted.
  Future<List<Event>> searchEvents(
    String? name,
    Position? currentPosition, {
    FilterOptions filter = const FilterOptions(),
  }) async {
    var events = _firestore.collection('events');
    var query = events.where(Event.attr.visibility, isEqualTo: 'public');

    // force a value to reuse index
    query = query.where(
      Event.attr.startDate,
      isGreaterThanOrEqualTo: filter.startAfter ?? DateTime.now(),
    );
    query = query.where(
      Event.attr.startDate,
      isLessThanOrEqualTo: filter.startBefore,
    );
    query = query.where(
      Event.attr.participantCount,
      isLessThanOrEqualTo: filter.maxParticipants,
    );
    // a value to reuse the index which includes participants
    query = query.where(
      Event.attr.participantCount,
      isGreaterThanOrEqualTo: filter.minParticipants ?? 0,
    );

    var snapshot = await query.get();
    return snapshot.docs.map((doc) => Event.fromDocument(doc)).toList();
  }
}

class FilterOptions {
  final int? distanceKilometers;
  final DateTime? startAfter;
  final DateTime? startBefore;
  final int? minParticipants;
  final int? maxParticipants;
  const FilterOptions({
    this.distanceKilometers,
    this.startAfter,
    this.startBefore,
    this.minParticipants,
    this.maxParticipants,
  });
}
