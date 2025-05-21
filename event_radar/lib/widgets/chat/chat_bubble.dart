import 'package:flutter/material.dart';

import '../../core/models/chat_message.dart';
import '../../core/models/participant.dart';
import '../../core/util/date_time_format.dart';
import '../avatar_or_placeholder.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final ParticipantProfile? senderProfile;
  final bool showSender;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.senderProfile,
    this.showSender = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSystemMessage =
        message.type != 'text' && message.type != 'image';
    final String timeString = formatTime(message.createdAt);

    if (isSystemMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${message.text} - $timeString',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Anzeige von Avatar + Name über der Blase, wenn nicht 'me' und Profil da
              if (!isMe && senderProfile != null && showSender)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AvatarOrPlaceholder(
                        imageUrl: senderProfile!.photo,
                        name: senderProfile!.name,
                        radius: 12,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        senderProfile!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              Container(
                constraints: const BoxConstraints(maxWidth: 250),
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 12.0,
                ),
                decoration: BoxDecoration(
                  color: isMe ? Colors.lightGreen[200] : Colors.blue[100],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(isMe ? 12 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Nachrichtentext
                    Text(
                      message.text,
                      style: const TextStyle(
                        fontSize: 16.0,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Zeitstempel
                    Text(
                      timeString,
                      style: TextStyle(fontSize: 12.0, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
