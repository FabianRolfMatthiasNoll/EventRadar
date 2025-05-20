import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:collection/collection.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';

import '../models/event.dart';
import 'chat_service.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();

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
      'channelName': 'Announcements',
      'channelType': 'announcement',
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

  Stream<List<Event>> getPublicEventsStream() {
    return _firestore
        .collection('events')
        .where('visibility', isEqualTo: 'public')
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => Event.fromDocument(doc)).toList(),
        );
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

  Future<void> updateEvent(String eventId, Map<String, dynamic> data) {
    return _firestore.collection('events').doc(eventId).update(data);
  }

  Future<void> logEventChange(
    String eventId,
    Map<String, dynamic> change,
  ) async {
    final channelId = await _chatService.getAnnouncementChannelId(eventId);
    final messagesRef = _firestore
        .collection('events')
        .doc(eventId)
        .collection('channels')
        .doc(channelId)
        .collection('messages');

    final type = change['type'] as String? ?? '';
    late String text;
    switch (type) {
      case 'title_change':
        text = 'Titel wurde geändert';
        break;
      case 'description_change':
        text = 'Beschreibung wurde geändert';
        break;
      case 'date_change':
        text = 'Datum wurde geändert';
        break;
      case 'end_date_change':
        text = 'Enddatum wurde geändert';
        break;
      case 'image_change':
        text = 'Profilbild/Veranstaltungsbild wurde geändert';
        break;
      case 'location_change':
        text = 'Ort wurde geändert';
        break;
      default:
        text = 'Event wurde aktualisiert';
    }

    await messagesRef.add({
      'text': text,
      'type': 'update',
      'senderId': 'system',
      'createdAt': FieldValue.serverTimestamp(),
      'metadata': change,
    });
  }

  Future<void> changeParticipantRole(
    String eventId,
    String userId,
    String newRole,
  ) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .doc(userId)
        .update({'role': newRole});
  }

  Future<void> deleteEvent(String eventId) async {
    final callable = FirebaseFunctions.instance.httpsCallable('deleteEvent');
    final result = await callable.call({'eventId': eventId});
    // the function returns { success: true } on completion
    if (result.data is Map && (result.data as Map)['success'] != true) {
      throw Exception("Event deletion failed");
    }
  }

  /// For this function to work there needs to be the following index on events:
  /// (visibility,date,participantCount,__name__).
  /// If the order or amount of filters are changed the index must be adjusted.
  Future<List<Event>> searchEvents(
    String? searchText, {
    Position? currentPosition,
    FilterOptions filter = const FilterOptions(),
    SortOption sort = SortOption.date,
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
    // force a value to reuse the index which includes participants
    query = query.where(
      Event.attr.participantCount,
      isGreaterThanOrEqualTo: filter.minParticipants ?? 0,
    );

    var snapshot = await query.get();
    var docs = snapshot.docs.map((doc) => Event.fromDocument(doc));

    if (filter.distanceKilometers != null && currentPosition != null) {
      docs = docs.where((e) {
        return filter.distanceKilometers! >=
            Geolocator.distanceBetween(
                  e.location.latitude,
                  e.location.longitude,
                  currentPosition.latitude,
                  currentPosition.longitude,
                ) /
                1000;
      });
    }
    if (searchText != null && searchText.isNotEmpty) {
      docs = docs.where(
        (e) => e.title.toLowerCase().contains(searchText.toLowerCase()),
      );
    }
    // sorting locally because on firebase it would require an extra index
    switch (sort) {
      case SortOption.participantsAsc:
        return docs.sortedBy((e) => e.participantCount);
      case SortOption.participantsDesc:
        return docs.sortedBy((e) => -e.participantCount);
      case SortOption.distance:
        if (sort == SortOption.distance && currentPosition != null) {
          return docs.sortedBy((e) {
            return Geolocator.distanceBetween(
              e.location.latitude,
              e.location.longitude,
              currentPosition.latitude,
              currentPosition.longitude,
            );
          });
        }
      case _:
        break;
    }
    return docs.toList();
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

enum SortOption { distance, date, participantsAsc, participantsDesc }
