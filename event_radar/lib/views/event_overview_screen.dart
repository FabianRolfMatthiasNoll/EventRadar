import 'package:event_radar/widgets/avatar_or_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/models/event.dart';
import '../core/models/participant.dart';
import '../core/services/auth_service.dart';
import '../core/services/event_service.dart';
import '../core/util/date_time_format.dart';
import '../core/viewmodels/event_overview_viewmodel.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/static_map_snippet.dart';

class EventOverviewScreen extends StatelessWidget {
  final String eventId;
  const EventOverviewScreen({super.key, required this.eventId});

  /// Shows a dialog to let the user select a new admin from the provided list of participants.
  /// Returns the UID of the selected new admin, or null if cancelled.
  Future<String?> _selectNewAdminDialog(
    BuildContext context,
    List<ParticipantProfile> candidates,
  ) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Neuen Admin auswählen"),
          content: SizedBox(
            height: 300,
            width: 300,
            child: ListView(
              children:
                  candidates.map((p) {
                    return ListTile(
                      title: Text(p.name),
                      onTap: () => Navigator.of(dialogContext).pop(p.uid),
                    );
                  }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Abbrechen"),
              onPressed: () => Navigator.of(dialogContext).pop(null),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleParticipation(
    BuildContext context,
    bool isParticipant,
    String userId,
    Event event,
  ) async {
    final currentUser = AuthService().currentUser();
    if (currentUser == null) return;
    final vm = context.read<EventOverviewViewModel>();
    final bool isAdminUser = vm.participants.any(
      (participant) =>
          participant.uid == userId && participant.role == 'organizer',
    );

    if (isParticipant) {
      // User is attempting to leave the event
      if (isAdminUser) {
        // Admin leaving
        // Count other admins in the event (besides current user)
        final otherAdmins =
            vm.participants
                .where((p) => p.role == 'organizer' && p.uid != userId)
                .toList();
        final bool otherAdminsExist = otherAdmins.isNotEmpty;
        // Count other participants (non-admins)
        final otherParticipants =
            vm.participants.where((p) => p.uid != userId).toList();
        final bool otherParticipantsExist = otherParticipants.isNotEmpty;

        if (otherAdminsExist) {
          // There are other admins, warn user will lose admin status
          bool confirmed = await showConfirmationDialog(
            context,
            "Event verlassen",
            "Wenn du dieses Event verlässt, verlierst du deinen Admin-Status.",
          );
          if (!confirmed) return;
          // Proceed to leave normally below
        } else if (otherParticipantsExist) {
          // User is the only admin, but there are other participants
          bool assignConfirmed = await showConfirmationDialog(
            context,
            "Event verlassen",
            "Du bist der einzige Admin. Möchtest du einen anderen Teilnehmer zum Admin machen?",
          );
          if (!assignConfirmed) return;
          // Let user choose a new admin from remaining participants
          String? newAdminId = await _selectNewAdminDialog(
            context,
            otherParticipants,
          );
          if (newAdminId == null) {
            // User cancelled selecting a new admin, do not leave
            return;
          }
          // Promote the selected participant to admin (organizer)
          try {
            await EventService().changeParticipantRole(
              event.id!,
              newAdminId,
              'organizer',
            );
          } catch (e) {
            // If assigning new admin fails, show error and abort leaving
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fehler: Admin konnte nicht übertragen. ($e)'),
              ),
            );
            return;
          }
          // Now another admin exists, so current user can leave safely
          bool confirmed = await showConfirmationDialog(
            context,
            "Event verlassen",
            "Neuer Admin wurde ernannt. Möchtest du das Event jetzt verlassen?",
          );
          if (!confirmed) {
            // If user decides not to leave after all (even after assigning), we might consider reverting the new admin,
            // but for simplicity we keep the new admin and just abort the leave.
            return;
          }
          // Proceed to leave
        } else {
          // User is the last participant (and an admin)
          bool confirmed = await showConfirmationDialog(
            context,
            "Event verlassen",
            "Du bist der letzte Teilnehmer. Wenn du gehst, wird das Event gelöscht.",
          );
          if (!confirmed) return;
          // Call Cloud Function to delete the event entirely
          try {
            await EventService().deleteEvent(event.id!);
            if (!context.mounted) return;
            Navigator.of(context).pop(); // leave the event screen
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Event gelöscht")));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Fehler beim Löschen des Events: $e')),
            );
          }
          return; // We return because event is deleted and user has left (screen popped).
        }
      } else {
        // Normal participant (not admin) leaving
        bool confirmed = await showConfirmationDialog(
          context,
          "Event verlassen",
          "Bist du sicher, dass du das Event verlassen willst?",
        );
        if (!confirmed) return;
        // Proceed to leave normally
      }

      // If we reach here, the user has confirmed leaving (and any necessary admin handling done).
      try {
        await EventService().leaveEvent(event.id!, userId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Event verlassen")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: Event konnte nicht verlassen werden. ($e)'),
          ),
        );
      }
    } else {
      // User is not a participant yet (joining the event)
      bool confirmed = await showConfirmationDialog(
        context,
        "Event beitreten",
        "Möchtest du dich bei diesem Event eintragen?",
      );
      if (!confirmed) return;
      try {
        await EventService().joinEvent(event.id!, userId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Event beigetreten")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: Konnte Event nicht beitreten. ($e)')),
        );
      }
    }
  }

  Future<void> _openGoogleMaps(BuildContext context, Event event) async {
    final lat = event.location.latitude;
    final lng = event.location.longitude;
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Maps konnte nicht geöffnet werden'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser();

    return MainScaffold(
      title: 'Event Details',
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // TODO: Navigate to event settings.
          },
        ),
      ],
      body: StreamBuilder<Event>(
        stream: EventService().getEventStream(eventId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return const Center(child: Text("Fehler beim Laden des Events"));
          }

          final event = snap.data!;
          final isPart =
              currentUser != null &&
              event.participants.contains(currentUser.uid);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: event image and name.
                Row(
                  children: [
                    AvatarOrPlaceholder(
                      imageUrl: event.image,
                      name: event.title,
                      radius: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Description.
                if (event.description != null && event.description!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(event.description!),
                  ),
                // Start and End Date.
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title:
                      event.endDate != null
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Start: ${formatDateTime(event.startDate)}"),
                              const SizedBox(height: 4),
                              Text("Ende:  ${formatDateTime(event.endDate!)}"),
                            ],
                          )
                          : Text(formatDateTime(event.startDate)),
                ),
                // Participants.
                ListTile(
                  leading: const Icon(Icons.people),
                  title: Text("${event.participantCount} Teilnehmer"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    final vm = context.read<EventOverviewViewModel>();
                    showModalBottomSheet(
                      context: context,
                      builder: (_) {
                        return ChangeNotifierProvider.value(
                          value: vm,
                          child: Consumer<EventOverviewViewModel>(
                            builder: (ctx, vm, __) {
                              if (vm.isLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (vm.error != null) {
                                return Center(
                                  child: Text("Fehler: ${vm.error}"),
                                );
                              }
                              if (vm.participants.isEmpty) {
                                return const Center(
                                  child: Text("Keine Teilnehmer."),
                                );
                              }
                              return ListView(
                                children:
                                    vm.participants.map((p) {
                                      return ListTile(
                                        leading: AvatarOrPlaceholder(
                                          imageUrl: p.photo,
                                          name: p.name,
                                        ),
                                        title: Text(p.name),
                                        subtitle: Text(p.role),
                                      );
                                    }).toList(),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
                // Announcements
                if (isPart)
                  ListTile(
                    leading: const Icon(Icons.announcement),
                    title: const Text("Announcements"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // TODO: Navigate to announcements.
                    },
                  ),
                const SizedBox(height: 16),
                // Location snippet.
                GestureDetector(
                  onTap: () => _openGoogleMaps(context, event),
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: StaticMapSnippet(
                      location: LatLng(
                        event.location.latitude,
                        event.location.longitude,
                      ),
                      width: 600,
                      height: 150,
                      zoom: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Join/Leave Button
                Center(
                  child: ElevatedButton(
                    onPressed:
                        currentUser != null
                            ? () => _toggleParticipation(
                              context,
                              isPart,
                              currentUser.uid,
                              event,
                            )
                            : null,
                    child: Text(isPart ? "Event verlassen" : "Event beitreten"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
