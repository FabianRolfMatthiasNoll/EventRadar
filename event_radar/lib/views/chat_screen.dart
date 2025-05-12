// views/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/viewmodels/chat_viewmodel.dart';
import '../widgets/chat/chat_bubble.dart';
import '../widgets/chat/chat_input_field.dart';
import '../widgets/chat/survey_bubble.dart';

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
  const _ChatContent({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();

    if (vm.isLoading) {
      Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: vm.messages.length,
            itemBuilder: (context, index) {
              final msg = vm.messages[index];

              if (msg.type == 'survey') {
                return SurveyBubble(
                  eventId: vm.eventId,
                  channelId: vm.channelId,
                  message: msg,
                  votes: vm.votesFor(msg.id),
                  currentUserId: vm.currentUserId,
                  onVote: (opt) => vm.voteSurvey(msg.id, opt),
                  onClose:
                      msg.senderId == vm.currentUserId
                          ? () => vm.closeSurvey(msg.id)
                          : null,
                  onDelete:
                      msg.senderId == vm.currentUserId
                          ? () => vm.deleteSurvey(msg.id)
                          : null,
                );
              }

              final isMe = msg.senderId == vm.currentUserId;
              final profile = vm.participantMap[msg.senderId];
              final showSender =
                  index == 0 || vm.messages[index - 1].senderId != msg.senderId;

              return ChatBubble(
                message: msg,
                isMe: isMe,
                senderProfile: profile,
                showSender: showSender,
              );
            },
          ),
        ),
        ChatInputField(
          onSend: vm.sendMessage,
          onCreateSurvey: (s) => vm.createSurvey(s.question, s.options),
        ),
      ],
    );
  }
}
