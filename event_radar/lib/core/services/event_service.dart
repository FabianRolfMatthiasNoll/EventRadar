import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/event.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> uploadEventImage(File imageFile) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child("event_images")
        .child("${DateTime.now().millisecondsSinceEpoch}.jpg");
    final uploadTask = storageRef.putFile(imageFile);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> createEvent(Event event, {File? imageFile}) async {
    String imageUrl;
    if (imageFile != null) {
      imageUrl = await uploadEventImage(imageFile);
    } else {
      imageUrl = event.image;
    }

    // Erstelle das Event-Dokument
    DocumentReference eventRef = await _firestore.collection('events').add({
      'title': event.title,
      'date': event.date,
      'location': event.location,
      'visibility': event.visibility,
      'description': event.description,
      'image': imageUrl,
      'createdAt': DateTime.now(),
      'creatorId': event.creatorId,
      'promoted': event.promoted,
    });

    // Standard-Chat-Kanal als Subcollection anlegen
    DocumentReference channelRef = await eventRef.collection('channels').add({
      'channelName': 'Standard Chat',
      'channelType': 'main',
      'createdAt': DateTime.now(),
    });

    // Erstelle die erste Nachricht im Kanal
    await channelRef.collection('messages').add({
      'text': 'Event wurde erstellt',
      'type': 'update',
      'senderId': 'admin', // TODO: Hier später UserID verwenden
      'createdAt': DateTime.now(),
      'metadata': {},
    });
  }

  Future<List<Event>> getEvents() async {
    QuerySnapshot snapshot = await _firestore.collection('events').get();
    List<Event> events = snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return Event(
        title: data['title'] ?? '',
        date: data['date']?.toDate() ?? DateTime.now(),
        location: data['location'],
        visibility: data['visibility'] ?? 'public',
        description: data['description'],
        image: data['image'] ?? '',
        creatorId: data['creatorId'] ?? '',
        promoted: data['promoted'] ?? false,
      );
    }).toList();
    return events;
  }
}
