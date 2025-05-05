import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/viewmodels/announcement_chat_viewmodel.dart';
import '../widgets/chat/chat_bubble.dart';
import '../widgets/chat/chat_input_field.dart';

class AnnouncementChatScreen extends StatelessWidget {
  final String eventId;
  const AnnouncementChatScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AnnouncementChatViewModel(eventId),
      child: const _AnnouncementChatContent(),
    );
  }
}

class _AnnouncementChatContent extends StatelessWidget {
  const _AnnouncementChatContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnnouncementChatViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: SafeArea(
        child: Column(
          children: [
            // Nachrichtenliste
            Expanded(
              child: Builder(
                builder: (_) {
                  if (vm.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (vm.errorMessage != null) {
                    return Center(
                      child: Text(
                        vm.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (vm.messages.isEmpty) {
                    return const Center(
                      child: Text('Keine Nachrichten vorhanden.'),
                    );
                  }
                  // ListView mit Nachrichten
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    itemCount: vm.messages.length,
                    itemBuilder: (context, index) {
                      final message = vm.messages[index];
                      // Prüfen, ob die Nachricht vom aktuellen User stammt (für Ausrichtung/Farbe)
                      final isMe =
                          message.senderId ==
                          FirebaseAuth.instance.currentUser?.uid;
                      final profile = vm.participantMap[message.senderId];
                      return ChatBubble(
                        message: message,
                        isMe: isMe,
                        senderProfile: profile,
                      );
                    },
                  );
                },
              ),
            ),
            if (vm.isOrganizer)
              ChatInputField(
                onSend: (text) {
                  vm.sendMessage(text);
                },
              ),
          ],
        ),
      ),
    );
  }
}
