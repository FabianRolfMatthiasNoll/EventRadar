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
  final bool isAnnouncement;

  const ChatScreen({
    super.key,
    required this.eventId,
    required this.channelId,
    required this.channelName,
    this.isAnnouncement = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatViewModel>(
      create: (_) => ChatViewModel(eventId: eventId, channelId: channelId),
      child: Scaffold(
        appBar: AppBar(title: Text(channelName)),
        body: SafeArea(
          child: Consumer<ChatViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      itemCount: vm.messages.length,
                      itemBuilder: (context, index) {
                        final msg = vm.messages[index];
                        if (msg.type == 'survey') {
                          return SurveyBubble(
                            eventId: eventId,
                            channelId: channelId,
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
                            index == 0 ||
                            vm.messages[index - 1].type != 'text' ||
                            vm.messages[index - 1].senderId != msg.senderId;
                        return ChatBubble(
                          message: msg,
                          isMe: isMe,
                          senderProfile: profile,
                          showSender: showSender,
                        );
                      },
                    ),
                  ),
                  if (!isAnnouncement || vm.isOrganizer)
                    ChatInputField(
                      onSend: vm.sendMessage,
                      onCreateSurvey:
                          (surveyData) => vm.createSurvey(
                            surveyData.question,
                            surveyData.options,
                          ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
