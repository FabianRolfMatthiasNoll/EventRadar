import 'dart:async';

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

  StreamSubscription? _sub;

  ChatViewModel(this.eventId, this.channelId) {
    _init();
  }
  void _init() async {
    final parts = await ParticipantService.fetch(eventId);
    participantMap = {for (var p in parts) p.uid: p};

    _sub = _svc.streamMessages(eventId, channelId).listen((msgs) {
      messages = msgs;
      isLoading = false;
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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
