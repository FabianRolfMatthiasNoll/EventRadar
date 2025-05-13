import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/viewmodels/chat_viewmodel.dart';
import '../widgets/chat/chat_bubble.dart';
import '../widgets/chat/chat_input_field.dart';
import '../widgets/chat/survey_bubble.dart';
import '../widgets/chat/survey_list_sheet.dart';

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
      create:
          (_) => ChatViewModel(
            eventId: eventId,
            channelId: channelId,
            isAnnouncement: isAnnouncement,
          ),
      child: Consumer<ChatViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(channelName),
              actions: [
                IconButton(
                  icon: const Icon(Icons.poll),
                  tooltip: "Alle Umfragen",
                  onPressed: () {
                    final surveys =
                        vm.messages.where((m) => m.type == "survey").toList();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => SurveyListSheet(surveys: surveys, vm: vm),
                    );
                  },
                ),
              ],
            ),
            body: SafeArea(
              child:
                  vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
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

                                // Survey‐Nachricht
                                if (msg.type == "survey") {
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

                                // Normale Text‐Nachricht
                                final isMe = msg.senderId == vm.currentUserId;
                                final profile = vm.participantMap[msg.senderId];
                                final showSender =
                                    index == 0 ||
                                    vm.messages[index - 1].type != "text" ||
                                    vm.messages[index - 1].senderId !=
                                        msg.senderId;

                                return ChatBubble(
                                  message: msg,
                                  isMe: isMe,
                                  senderProfile: profile,
                                  showSender: showSender,
                                );
                              },
                            ),
                          ),

                          // Input nur in Chat oder als Organisator im Announcement
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
                      ),
            ),
          );
        },
      ),
    );
  }
}
