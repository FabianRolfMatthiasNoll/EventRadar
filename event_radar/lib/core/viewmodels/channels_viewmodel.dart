import 'package:flutter/material.dart';

import '../models/chat_channel.dart';
import '../services/chat_service.dart';

class ChannelsViewModel extends ChangeNotifier {
  final String eventId;
  final ChatService _service = ChatService();

  bool isLoading = true;
  String? error;
  List<ChatChannel> channels = [];

  ChannelsViewModel(this.eventId) {
    _load();
  }

  Future<void> _load() async {
    try {
      final annId = await _service.getAnnouncementChannelId(eventId);
      channels = [ChatChannel(annId, 'Announcements', 'announcement')];
      final docs = await _service.listChatChannels(eventId);
      channels.addAll(
        docs.map((d) => ChatChannel(d.id, d['channelName'], d['channelType'])),
      );
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createChat(String name) async {
    await _service.createChatChannel(eventId, name);
    await _load();
  }

  Future<void> deleteChat(String channelId) async {
    await _service.deleteChatChannel(eventId, channelId);
    await _load();
  }
}
