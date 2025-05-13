import 'package:event_radar/widgets/participant_tile.dart';
import 'package:flutter/material.dart';

import '../core/models/participant.dart';
import '../core/viewmodels/event_overview_viewmodel.dart';
import 'confirm_dialog.dart';

class ParticipantsListSheet extends StatelessWidget {
  final EventOverviewViewModel vm;
  const ParticipantsListSheet({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.isParticipantsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.participantsError != null) {
      return Center(child: Text("Fehler: ${vm.participantsError}"));
    }
    if (vm.participants.isEmpty) {
      return const Center(child: Text("Keine Teilnehmer."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vm.participants.length,
      itemBuilder: (ctx, i) {
        final p = vm.participants[i];
        return ParticipantTile(
          participant: p,
          isOrganizer: vm.isOrganizer == true,
          onAction: (choice) => _handleChoice(context, vm, p, choice),
        );
      },
    );
  }

  void _handleChoice(
    BuildContext context,
    EventOverviewViewModel vm,
    ParticipantProfile p,
    ParticipantAction choice,
  ) async {
    switch (choice) {
      case ParticipantAction.promote:
        await vm.promoteToOrganizer(p.uid);
        break;
      case ParticipantAction.demote:
        await vm.demoteFromOrganizer(p.uid);
        break;
      case ParticipantAction.kick:
        final ok = await showConfirmationDialog(
          context,
          'Teilnehmer entfernen',
          'Willst du ${p.name} wirklich entfernen?',
        );
        if (ok) await vm.kickParticipant(p.uid);
        break;
      default:
        break;
    }
    if (context.mounted) Navigator.of(context).pop();
  }
}
