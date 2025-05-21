import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SurveyDetailSheet extends StatelessWidget {
  final String eventId;
  final String channelId;
  final String messageId;
  final String question;
  final List<Map<String, dynamic>> options;
  final String currentUserId;
  final ValueChanged<String> onVote;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;
  final bool closed;

  const SurveyDetailSheet({
    super.key,
    required this.eventId,
    required this.channelId,
    required this.messageId,
    required this.question,
    required this.options,
    required this.currentUserId,
    required this.onVote,
    this.onClose,
    this.onDelete,
    required this.closed,
  });

  @override
  Widget build(BuildContext context) {
    final votesStream =
        FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .collection('channels')
            .doc(channelId)
            .collection('messages')
            .doc(messageId)
            .collection('votes')
            .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: votesStream,
      builder: (context, snap) {
        final votes = snap.data?.docs ?? [];

        return Padding(
          // Platz für Keyboard und Abstand nach oben/unten
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Frage: unbegrenzt lang
                Text(question, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),

                // Optionen als einfache ListTiles
                ...options.map((opt) {
                  final optId = opt['id'] as String;
                  final text = opt['text'] as String? ?? '';
                  final count =
                      votes.where((v) {
                        final data = v.data() as Map<String, dynamic>? ?? {};
                        return data['optionId'] == optId;
                      }).length;
                  final isMyVote = votes.any((v) {
                    final data = v.data() as Map<String, dynamic>? ?? {};
                    return v.id == currentUserId && data['optionId'] == optId;
                  });

                  return ListTile(
                    title: Text(text),
                    leading:
                        closed
                            ? null
                            : Radio<String>(
                              value: optId,
                              groupValue: isMyVote ? optId : null,
                              onChanged: (_) => onVote(optId),
                            ),
                    trailing: Text(
                      count.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 16),

                // Aktionen
                if (onClose != null && !closed)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.lock),
                    label: const Text('Umfrage schließen'),
                    onPressed: () {
                      Navigator.pop(context);
                      onClose!();
                    },
                  ),
                if (onDelete != null)
                  TextButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Löschen'),
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete!();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
