import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getAnnouncementChannelId(String eventId) async {
    final eventRef = _firestore.collection('events').doc(eventId);
    final query =
        await eventRef
            .collection('channels')
            .where('channelType', isEqualTo: 'announcement')
            .limit(1)
            .get();
    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }
    // Falls aus irgendeinem Grund nicht vorhanden (alte Events): neuen Announcement-Channel erstellen.
    final channelRef = await eventRef.collection('channels').add({
      'channelName': 'Announcements',
      'channelType': 'announcement',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return channelRef.id;
  }

  Stream<List<ChatMessage>> streamMessages(String eventId, String channelId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromDocument(doc))
              .toList();
        });
  }

  Future<void> sendMessage(
    String eventId,
    String channelId,
    ChatMessage message,
  ) async {
    final messagesRef = _firestore
        .collection('events')
        .doc(eventId)
        .collection('channels')
        .doc(channelId)
        .collection('messages');
    final data = message.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await messagesRef.add(data);
  }
}
