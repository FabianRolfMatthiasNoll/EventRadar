import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_radar/widgets/chat/survey_details_sheet.dart';
import 'package:flutter/material.dart';

import '../../../core/models/chat_message.dart';

class SurveyBubble extends StatelessWidget {
  final ChatMessage message;
  final List<DocumentSnapshot> votes;
  final String currentUserId;
  final ValueChanged<String> onVote;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;
  final String eventId;
  final String channelId;

  const SurveyBubble({
    super.key,
    required this.message,
    required this.votes,
    required this.currentUserId,
    required this.onVote,
    required this.eventId,
    required this.channelId,
    this.onClose,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final meta = (message.metadata ?? {});
    final question = meta['question'] as String? ?? '';
    final options =
        (meta['options'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final closed = meta['closed'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap:
            () => _showDetailSheet(context, question, options, votes, closed),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: closed ? Colors.grey[200] : Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📊 $question',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(closed ? 'Abgeschlossen' : 'Tippe für Details…'),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(
    BuildContext context,
    String question,
    List<Map<String, dynamic>> options,
    List<DocumentSnapshot> votes,
    bool closed,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => SurveyDetailSheet(
            eventId: eventId,
            channelId: channelId,
            messageId: message.id,
            question: question,
            options: options,
            currentUserId: currentUserId,
            onVote: onVote,
            onClose: onClose,
            onDelete: onDelete,
            closed: closed,
          ),
    );
  }
}
