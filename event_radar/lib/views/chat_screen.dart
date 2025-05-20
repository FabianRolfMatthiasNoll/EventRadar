import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/notification_provider.dart';
import '../core/viewmodels/chat_viewmodel.dart';
import '../widgets/chat/chat_bubble.dart';
import '../widgets/chat/chat_input_field.dart';
import '../widgets/chat/survey_bubble.dart';
import '../widgets/chat/survey_list_sheet.dart';
import '../widgets/main_scaffold.dart';

class ChatScreen extends StatefulWidget {
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
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ScrollController _scrollController;
  NotificationProvider? _notificationProvider;
  bool _didSetActive = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didSetActive && widget.isAnnouncement) {
      // Provider holen und speichern
      _notificationProvider = context.read<NotificationProvider>();
      _notificationProvider!.setActiveAnnouncement(
        widget.eventId,
        widget.channelId,
      );
      _didSetActive = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    // Wenn wir einen NotificationProvider haben, löschen wir die
    // aktive Announcement-Markierung erst im nächsten Frame.
    if (_notificationProvider != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notificationProvider!.setActiveAnnouncement(null, null);
      });
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatViewModel>(
      create:
          (_) => ChatViewModel(
            eventId: widget.eventId,
            channelId: widget.channelId,
            isAnnouncement: widget.isAnnouncement,
          ),
      child: Consumer<ChatViewModel>(
        builder: (context, vm, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(
                _scrollController.position.maxScrollExtent,
              );
            }
          });

          return MainScaffold(
            title: widget.channelName,
            appBarActions: [
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
            body: SafeArea(
              child:
                  vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
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
                                    eventId: widget.eventId,
                                    channelId: widget.channelId,
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

                          // Eingabefeld nur in Chat-Räumen oder als Organizer im Announcement-Channel
                          if (!widget.isAnnouncement || vm.isOrganizer)
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
