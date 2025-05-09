// views/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/viewmodels/chat_viewmodel.dart';
import '../widgets/chat/chat_bubble.dart';
import '../widgets/chat/chat_input_field.dart';

class ChatScreen extends StatelessWidget {
  final String eventId;
  final String channelId;
  final String channelName;

  const ChatScreen({
    super.key,
    required this.eventId,
    required this.channelId,
    required this.channelName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(eventId, channelId),
      child: Scaffold(
        appBar: AppBar(title: Text(channelName)),
        body: SafeArea(child: _ChatContent()),
      ),
    );
  }
}

class _ChatContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    return Column(
      children: [
        Expanded(
          child:
              vm.isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                    itemCount: vm.messages.length,
                    itemBuilder: (_, i) {
                      final msg = vm.messages[i];
                      final isMe = msg.senderId == vm.currentUserId;
                      final profile = vm.participantMap[msg.senderId];
                      final showSender =
                          i == 0 || vm.messages[i - 1].senderId != msg.senderId;
                      return ChatBubble(
                        message: msg,
                        isMe: isMe,
                        senderProfile: profile,
                        showSender: showSender,
                      );
                    },
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                  ),
        ),
        ChatInputField(onSend: vm.sendMessage),
      ],
    );
  }
}
