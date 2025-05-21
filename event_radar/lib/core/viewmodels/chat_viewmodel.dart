// lib/core/viewmodels/chat_viewmodel.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/participant.dart';
import '../services/chat_service.dart';
import '../services/participant_service.dart';

class ChatViewModel extends ChangeNotifier {
  final String eventId;
  final String channelId;
  final bool isAnnouncement;
  bool isOrganizer = false;
  final ChatService _svc = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  List<ChatMessage> messages = [];
  Map<String, ParticipantProfile> participantMap = {};
  bool isLoading = true;

  final Map<String, List<DocumentSnapshot>> _surveyVotes = {};
  final Set<String> _surveySubscribed = {};
  final List<StreamSubscription<List<DocumentSnapshot>>> _voteSubs = [];

  List<DocumentSnapshot> votesFor(String messageId) =>
      _surveyVotes[messageId] ?? [];

  late final StreamSubscription<List<ChatMessage>> _messageSub;

  ChatViewModel({
    required this.eventId,
    required this.channelId,
    this.isAnnouncement = false,
  }) {
    _init();
  }

  void _init() async {
    final parts = await ParticipantService.fetch(eventId);
    participantMap = {for (var p in parts) p.uid: p};

    _checkIfOrganizer();

    _messageSub = _svc.streamMessages(eventId, channelId).listen((msgs) {
      messages = msgs;
      for (var msg in msgs) {
        if (msg.type == 'survey' && !_surveySubscribed.contains(msg.id)) {
          _surveySubscribed.add(msg.id);
          final sub = _svc.streamSurveyVotes(eventId, channelId, msg.id).listen(
            (docs) {
              _surveyVotes[msg.id] = docs;
              notifyListeners();
            },
          );
          _voteSubs.add(sub);
        }
      }
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _checkIfOrganizer() async {
    final user = _auth.currentUser;
    if (user == null) {
      isOrganizer = false;
      notifyListeners();
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
    notifyListeners();
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

  Future<void> createSurvey(
    String question,
    List<Map<String, String>> options,
  ) {
    return _svc.createSurvey(eventId, channelId, question, options);
  }

  Future<void> voteSurvey(String messageId, String optionId) {
    return _svc.voteSurvey(eventId, channelId, messageId, optionId);
  }

  Future<void> closeSurvey(String messageId) {
    return _svc.closeSurvey(eventId, channelId, messageId);
  }

  Future<void> deleteSurvey(String messageId) {
    return _svc.deleteMessage(eventId, channelId, messageId);
  }

  @override
  void dispose() {
    for (var sub in _voteSubs) {
      sub.cancel();
    }
    _messageSub.cancel();
    super.dispose();
  }
}
