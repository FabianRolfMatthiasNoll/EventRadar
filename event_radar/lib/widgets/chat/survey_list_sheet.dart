import 'package:flutter/material.dart';

import '../../core/models/chat_message.dart';
import '../../core/viewmodels/chat_viewmodel.dart';
import 'survey_details_sheet.dart';

enum SurveySort { date, openFirst, closedFirst }

class SurveyListSheet extends StatefulWidget {
  final List<ChatMessage> surveys;
  final ChatViewModel vm;

  const SurveyListSheet({super.key, required this.surveys, required this.vm});

  @override
  State<SurveyListSheet> createState() => _SurveyListSheetState();
}

class _SurveyListSheetState extends State<SurveyListSheet> {
  SurveySort _sort = SurveySort.date;

  List<ChatMessage> get _sortedSurveys {
    final list = List<ChatMessage>.from(widget.surveys);
    switch (_sort) {
      case SurveySort.date:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SurveySort.openFirst:
        list.sort((a, b) {
          final aClosed = (a.metadata['closed'] as bool?) ?? false;
          final bClosed = (b.metadata['closed'] as bool?) ?? false;
          if (aClosed == bClosed) {
            return a.createdAt.compareTo(b.createdAt);
          }
          return aClosed ? 1 : -1;
        });
        break;
      case SurveySort.closedFirst:
        list.sort((a, b) {
          final aClosed = (a.metadata['closed'] as bool?) ?? false;
          final bClosed = (b.metadata['closed'] as bool?) ?? false;
          if (aClosed == bClosed) {
            return a.createdAt.compareTo(b.createdAt);
          }
          return aClosed ? -1 : 1;
        });
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final surveys = _sortedSurveys;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titel
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Alle Umfragen",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  SurveySort.values.map((sortOpt) {
                    final label =
                        {
                          SurveySort.date: "Datum",
                          SurveySort.openFirst: "Offen",
                          SurveySort.closedFirst: "Geschlossen",
                        }[sortOpt]!;
                    return ChoiceChip(
                      label: Text(label),
                      selected: _sort == sortOpt,
                      onSelected: (_) {
                        setState(() => _sort = sortOpt);
                      },
                    );
                  }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          if (surveys.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text("Keine Umfragen.", style: theme.textTheme.bodyMedium),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: surveys.length,
                itemBuilder: (context, i) {
                  final msg = surveys[i];
                  final closed = (msg.metadata["closed"] as bool?) ?? false;
                  final question =
                      msg.metadata["question"] as String? ?? "<ohne Frage>";
                  final opts =
                      (msg.metadata["options"] as List<dynamic>?)
                          ?.cast<Map<String, dynamic>>() ??
                      [];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    color: theme.cardColor,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      title: Text(
                        question,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        closed ? "Abgeschlossen" : "Offen",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              closed
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.primary,
                        ),
                      ),
                      trailing: Icon(
                        closed ? Icons.lock : Icons.poll_outlined,
                        color:
                            closed
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.primary,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder:
                              (_) => SurveyDetailSheet(
                                eventId: widget.vm.eventId,
                                channelId: widget.vm.channelId,
                                messageId: msg.id,
                                question: question,
                                options: opts,
                                currentUserId: widget.vm.currentUserId,
                                onVote:
                                    (opt) => widget.vm.voteSurvey(msg.id, opt),
                                onClose:
                                    widget.vm.currentUserId == msg.senderId
                                        ? () => widget.vm.closeSurvey(msg.id)
                                        : null,
                                onDelete:
                                    widget.vm.currentUserId == msg.senderId
                                        ? () => widget.vm.deleteSurvey(msg.id)
                                        : null,
                                closed: closed,
                              ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
