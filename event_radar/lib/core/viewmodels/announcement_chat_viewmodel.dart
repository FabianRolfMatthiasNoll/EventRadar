import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/participant.dart';
import '../services/chat_service.dart';
import '../services/participant_service.dart';

class AnnouncementChatViewModel extends ChangeNotifier {
  final String eventId;
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ChatMessage> messages = [];
  bool isOrganizer = false;
  bool isLoading = true;
  String? errorMessage;

  List<ParticipantProfile> participants = [];
  final Map<String, ParticipantProfile> participantMap = {};

  StreamSubscription<List<ChatMessage>>? _messagesSub;

  late final String channelId;

  AnnouncementChatViewModel(this.eventId) {
    _init();
  }

  void _init() async {
    _checkIfOrganizer();
    try {
      channelId = await _chatService.getAnnouncementChannelId(eventId);
      _messagesSub = _chatService
          .streamMessages(eventId, channelId)
          .listen(
            (List<ChatMessage> newMessages) {
              messages = newMessages;
              isLoading = false;
              errorMessage = null;
              notifyListeners();
            },
            onError: (error) {
              errorMessage = error.toString();
              isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      errorMessage = 'Fehler beim Laden des Chats: ${e.toString()}';
      isLoading = false;
      notifyListeners();
    }

    participants = await ParticipantService.fetch(eventId);
    participantMap
      ..clear()
      ..addEntries(participants.map((p) => MapEntry(p.uid, p)));
    notifyListeners();
  }

  Future<void> _checkIfOrganizer() async {
    final user = _auth.currentUser;
    if (user == null) {
      isOrganizer = false;
      return;
    }
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('events')
              .doc(eventId)
              .collection('participants')
              .doc(user.uid)
              .get();
      final role = doc.data()?['role'] as String?;
      isOrganizer = (role == 'organizer');
    } catch (_) {
      isOrganizer = false;
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final user = _auth.currentUser;
    if (user == null) return;
    final message = ChatMessage(
      id: '',
      text: text.trim(),
      senderId: user.uid,
      type: 'text',
      createdAt: DateTime.now(),
      metadata: {},
    );
    try {
      final channelId = await _chatService.getAnnouncementChannelId(eventId);
      await _chatService.sendMessage(eventId, channelId, message);
    } catch (e) {
      errorMessage = 'Senden fehlgeschlagen: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> createSurvey(
    String question,
    List<Map<String, String>> options,
  ) {
    return _chatService.createSurvey(eventId, channelId, question, options);
  }

  Future<void> voteSurvey(String messageId, String optionId) {
    return _chatService.voteSurvey(eventId, channelId, messageId, optionId);
  }

  Future<void> deleteSurvey(String messageId) {
    return _chatService.deleteMessage(eventId, channelId, messageId);
  }

  Future<void> closeSurvey(String messageId) {
    return _chatService.closeSurvey(eventId, channelId, messageId);
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    super.dispose();
  }
}
