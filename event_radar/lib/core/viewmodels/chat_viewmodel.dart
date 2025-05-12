import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/participant.dart';
import '../services/chat_service.dart';
import '../services/participant_service.dart';

class ChatViewModel extends ChangeNotifier {
  final String eventId, channelId;
  final ChatService _svc = ChatService();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  List<ChatMessage> messages = [];
  Map<String, ParticipantProfile> participantMap = {};
  bool isLoading = true;

  final Map<String, List<DocumentSnapshot>> _surveyVotes = {};
  final Set<String> _surveySubscribed = {};
  final List<StreamSubscription> _voteSubs = [];

  List<DocumentSnapshot> votesFor(String messageId) =>
      _surveyVotes[messageId] ?? [];

  late final StreamSubscription<List<ChatMessage>> _messageSub;

  ChatViewModel(this.eventId, this.channelId) {
    _init();
  }
  void _init() async {
    final parts = await ParticipantService.fetch(eventId);
    participantMap = {for (var p in parts) p.uid: p};

    _messageSub = _svc.streamMessages(eventId, channelId).listen((msgs) {
      messages = msgs;
      // für jede neue Umfrage den Vote‐Stream abonnieren
      for (var msg in msgs) {
        if (msg.type == 'survey' && !_surveySubscribed.contains(msg.id)) {
          _surveySubscribed.add(msg.id);
          // hier die Subscription speichern:
          final sub = _svc.streamSurveyVotes(eventId, channelId, msg.id).listen(
            (docs) {
              _surveyVotes[msg.id] = docs;
              notifyListeners();
            },
          );
          _voteSubs.add(sub);
        }
      }
      notifyListeners();
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final msg = ChatMessage(
      id: '',
      text: text.trim(),
      senderId: currentUserId,
      type: 'text',
      createdAt: DateTime.now(),
      metadata: {},
    );
    await _svc.sendMessage(eventId, channelId, msg);
  }

  void _listenSurveyVotes(String messageId) {
    _svc.streamSurveyVotes(eventId, channelId, messageId).listen((docs) {
      _surveyVotes[messageId] = docs;
      notifyListeners();
    });
  }

  Future<void> createSurvey(String question, List<Map<String, String>> opts) {
    return _svc.createSurvey(eventId, channelId, question, opts);
  }

  Future<void> voteSurvey(String messageId, String optionId) {
    return _svc.voteSurvey(eventId, channelId, messageId, optionId);
  }

  Future<void> deleteSurvey(String messageId) {
    return _svc.deleteMessage(eventId, channelId, messageId);
  }

  Future<void> closeSurvey(String messageId) {
    return _svc.closeSurvey(eventId, channelId, messageId);
  }

  @override
  void dispose() {
    // zuerst alle Votes‐Streams abbestellen
    for (var sub in _voteSubs) {
      sub.cancel();
    }
    // dann den Haupt‐Stream
    _messageSub.cancel();
    super.dispose();
  }
}
