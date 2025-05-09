import 'package:flutter/material.dart';

import '../core/models/participant.dart';
import 'avatar_or_placeholder.dart';

enum ParticipantAction { promote, demote, kick, none }

class ParticipantTile extends StatelessWidget {
  final ParticipantProfile participant;
  final bool isOrganizer;
  final void Function(ParticipantAction) onAction;

  const ParticipantTile({
    super.key,
    required this.participant,
    required this.isOrganizer,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AvatarOrPlaceholder(
        imageUrl: participant.photo,
        name: participant.name,
      ),
      title: Text(participant.name),
      subtitle: Text(participant.role),
      trailing:
          isOrganizer
              ? PopupMenuButton<ParticipantAction>(
                onSelected: onAction,
                itemBuilder:
                    (_) => [
                      if (participant.role != 'organizer')
                        const PopupMenuItem(
                          value: ParticipantAction.promote,
                          child: Text('Zum Organisator machen'),
                        ),
                      if (participant.role == 'organizer')
                        const PopupMenuItem(
                          value: ParticipantAction.demote,
                          child: Text('Organisator-Status entfernen'),
                        ),
                      const PopupMenuItem(
                        value: ParticipantAction.kick,
                        child: Text('Aus Event entfernen'),
                      ),
                    ],
              )
              : null,
      onTap: null,
    );
  }
}
