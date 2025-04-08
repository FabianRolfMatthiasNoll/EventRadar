import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  /// Retrieves all events from Firestore.
  Future<List<Event>> getEvents() async {
    QuerySnapshot snapshot = await _firestore.collection('events').get();
    return snapshot.docs.map((doc) => Event.fromDocument(doc)).toList();
  }
}
