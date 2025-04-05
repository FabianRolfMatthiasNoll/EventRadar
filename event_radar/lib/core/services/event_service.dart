import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createEvent(Event event) async {
    // Event-Dokument anlegen
    DocumentReference eventRef =
    await _firestore.collection('events').add(event.toMap());

    // Standard-Chat-Kanal als Subcollection erstellen
    DocumentReference channelRef =
    await eventRef.collection('channels').add({
      'channelName': 'Standard Chat',
      'channelType': 'main',
      'createdAt': DateTime.now(),
    });

    // Erste Nachricht im Kanal anlegen
    await channelRef.collection('messages').add({
      'text': 'Event wurde erstellt',
      'type': 'update',
      'senderId': 'admin', // TODO: Später gegen User ID austauschen
      'createdAt': DateTime.now(),
      'metadata': {},
    });
  }
}
