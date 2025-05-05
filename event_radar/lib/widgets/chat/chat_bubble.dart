import 'package:flutter/material.dart';

import '../../core/models/chat_message.dart';
import '../../core/util/date_time_format.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const ChatBubble({super.key, required this.message, required this.isMe});

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
      // Normale Organisator-Nachricht -> rechts- oder linksbündig mit farbiger Blase
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
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
                  style: const TextStyle(fontSize: 16.0, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                // Zeitstempel unterhalb des Textes
                Text(
                  timeString,
                  style: TextStyle(fontSize: 12.0, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
