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
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(question, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...options.map((opt) {
                final optId = opt['id'] as String;
                final count =
                    votes.where((v) {
                      final data = v.data() as Map<String, dynamic>? ?? {};
                      return data['optionId'] == optId;
                    }).length;
                final isMyVote = votes.any(
                  (v) =>
                      v.id == currentUserId &&
                      (v.data() as Map<String, dynamic>)['optionId'] == optId,
                );
                return ListTile(
                  title: Text(opt['text'] as String),
                  trailing: Text(count.toString()),
                  leading:
                      closed
                          ? null
                          : Radio<String>(
                            value: optId,
                            groupValue: isMyVote ? optId : null,
                            onChanged: (_) => onVote(optId),
                          ),
                );
              }),
              const SizedBox(height: 8),
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
        );
      },
    );
  }
}
