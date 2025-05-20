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
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Announcement-Channel immer zuerst
      final annId = await _service.getAnnouncementChannelId(eventId);
      channels = [
        ChatChannel(
          id: annId,
          name: 'Announcements',
          type: ChannelType.announcement,
        ),
      ];

      // Alle weiteren Chat-Channels vom Service holen
      final docs = await _service.listChatChannels(eventId);
      channels.addAll(
        docs.map((d) {
          final rawType = d['channelType'] as String? ?? '';
          final parsedType = ChannelType.values.firstWhere(
            (e) => e.name == rawType,
            orElse: () => ChannelType.chat,
          );
          return ChatChannel(
            id: d.id,
            name: d['channelName'] as String,
            type: parsedType,
          );
        }),
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
