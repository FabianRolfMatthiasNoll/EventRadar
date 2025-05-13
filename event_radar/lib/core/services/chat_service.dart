import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> _channels(String eventId) =>
      _firestore.collection('events').doc(eventId).collection('channels');

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

  Future<List<QueryDocumentSnapshot>> listChatChannels(String eventId) =>
      _channels(eventId)
          .where('channelType', isNotEqualTo: 'announcement')
          .orderBy('createdAt')
          .get()
          .then((q) => q.docs);

  Future<String> createChatChannel(String eventId, String channelName) async {
    final ref = await _channels(eventId).add({
      'channelName': channelName,
      'channelType': 'chat',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> deleteChatChannel(String eventId, String channelId) async {
    final channelRef = _channels(eventId).doc(channelId);
    final msgs = await channelRef.collection('messages').get();
    for (var doc in msgs.docs) {
      await doc.reference.delete();
    }
    await channelRef.delete();
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

  Future<void> deleteMessage(
    String eventId,
    String channelId,
    String messageId,
  ) async {
    final msgRef = _firestore
        .collection('events')
        .doc(eventId)
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .doc(messageId);
    final votes = await msgRef.collection('votes').get();
    for (var doc in votes.docs) {
      await doc.reference.delete();
    }
    await msgRef.delete();
  }

  Future<void> createSurvey(
    String eventId,
    String channelId,
    String question,
    List<Map<String, String>> options, // [{id, text}, …]
  ) {
    print('📊 createSurvey: event=$eventId channel=$channelId');
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .add({
          'text': '',
          'senderId': FirebaseAuth.instance.currentUser!.uid,
          'type': 'survey',
          'createdAt': FieldValue.serverTimestamp(),
          'metadata': {'question': question, 'options': options},
        });
  }

  Future<void> voteSurvey(
    String eventId,
    String channelId,
    String messageId,
    String optionId,
  ) {
    print(
      '🗳️ voteSurvey: event=$eventId channel=$channelId message=$messageId',
    );
    final voteRef = _firestore
        .collection('events')
        .doc(eventId)
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .doc(messageId)
        .collection('votes')
        .doc(FirebaseAuth.instance.currentUser!.uid);
    return voteRef.set({
      'optionId': optionId,
      'votedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> closeSurvey(String eventId, String channelId, String messageId) {
    final msgRef = _firestore
        .collection('events')
        .doc(eventId)
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .doc(messageId);
    return msgRef.update({'metadata.closed': true});
  }

  Stream<List<DocumentSnapshot>> streamSurveyVotes(
    String eventId,
    String channelId,
    String messageId,
  ) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .doc(messageId)
        .collection('votes')
        .snapshots()
        .map((snap) => snap.docs);
  }
}
