import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/event.dart';
import '../../core/models/participant.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/event_service.dart';
import '../../core/util/date_time_format.dart';
import '../../core/viewmodels/event_overview_viewmodel.dart';
import '../../widgets/avatar_or_placeholder.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/date_time_picker.dart';
import '../../widgets/image_picker.dart';
import '../../widgets/main_scaffold.dart';
import '../../widgets/static_map_snippet.dart';
import 'map_picker_screen.dart';

class EventOverviewScreen extends StatelessWidget {
  final String eventId;
  const EventOverviewScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventOverviewViewModel(eventId),
      child: _EventOverviewContent(),
    );
  }
}

class _EventOverviewContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventOverviewViewModel>();

    if (vm.isEventLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.eventError != null || vm.event == null) {
      final msg = vm.eventError ?? "Unbekannter Fehler";
      return Center(child: Text("Fehler beim Laden: $msg"));
    }

    final event = vm.event!;
    final currentUser = AuthService().currentUser();
    final isOrganizer = vm.isOrganizer == true;
    final isParticipant =
        currentUser != null && event.participants.contains(currentUser.uid);

    return MainScaffold(
      title: "Event Details",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, vm, event, isOrganizer),
            const SizedBox(height: 16),
            _buildDescription(context, vm, event, isOrganizer),
            _buildDateTile(context, vm, event, isOrganizer),
            _buildParticipantsTile(context, vm, event),
            if (isParticipant) _buildAnnouncementsTile(context),
            const SizedBox(height: 16),
            _buildMap(context, vm, event, isOrganizer),
            const SizedBox(height: 16),
            _buildJoinLeaveButton(context, vm, event, isParticipant),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    EventOverviewViewModel vm,
    Event event,
    bool isOrganizer,
  ) {
    return Row(
      children: [
        Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap:
                isOrganizer
                    ? () async {
                      final File? file = await pickAndCropImage();
                      if (file!.path.isNotEmpty) {
                        final newUrl = await EventService().uploadEventImage(
                          file,
                        );
                        await vm.updateImage(newUrl, event.image);
                      }
                    }
                    : null,
            child: AvatarOrPlaceholder(
              imageUrl: event.image,
              name: event.title,
              radius: 40,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap:
                  isOrganizer
                      ? () async {
                        final controller = TextEditingController(
                          text: event.title,
                        );
                        final result = await showDialog<String>(
                          context: context,
                          builder:
                              (ctx) => AlertDialog(
                                title: const Text("Titel ändern"),
                                content: TextField(controller: controller),
                                actions: [
                                  TextButton(
                                    child: const Text("Abbrechen"),
                                    onPressed: () => Navigator.of(ctx).pop(),
                                  ),
                                  TextButton(
                                    child: const Text("OK"),
                                    onPressed:
                                        () => Navigator.of(
                                          ctx,
                                        ).pop(controller.text),
                                  ),
                                ],
                              ),
                        );
                        if (result != null &&
                            result.isNotEmpty &&
                            result != event.title) {
                          await vm.updateTitle(result, event.title);
                        }
                      }
                      : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(
    BuildContext context,
    EventOverviewViewModel vm,
    Event event,
    bool isOrganizer,
  ) {
    final description = (event.description ?? '').trim();
    return ListTile(
      leading: const Icon(Icons.description),
      title: Text(
        description.isNotEmpty ? description : "Keine Beschreibung hinterlegt.",
      ),
      onTap:
          isOrganizer
              ? () async {
                final controller = TextEditingController(text: description);
                final result = await showDialog<String>(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text("Beschreibung ändern"),
                        content: TextField(
                          controller: controller,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: "Neue Beschreibung eingeben...",
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text("Abbrechen"),
                          ),
                          TextButton(
                            onPressed:
                                () => Navigator.of(
                                  ctx,
                                ).pop(controller.text.trim()),
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                );
                if (result != null && result != description) {
                  await vm.updateDescription(result, description);
                }
              }
              : null,
    );
  }

  Widget _buildDateTile(
    BuildContext context,
    EventOverviewViewModel vm,
    Event event,
    bool isOrganizer,
  ) {
    return ListTile(
      leading: const Icon(Icons.calendar_today),
      title:
          event.endDate != null
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Start: ${formatDateTime(event.startDate)}"),
                  const SizedBox(height: 4),
                  Text("Ende: ${formatDateTime(event.endDate!)}"),
                ],
              )
              : Text(formatDateTime(event.startDate)),
      onTap:
          isOrganizer ? () => _showDatePickerSheet(context, vm, event) : null,
    );
  }

  void _showDatePickerSheet(
    BuildContext context,
    EventOverviewViewModel vm,
    Event event,
  ) {
    DateTime? newStart;
    DateTime? newEnd;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DateTimePicker(
                    label: "Start:",
                    initialStart: event.startDate,
                    initialEnd: event.endDate,
                    onChanged: (s, e) {
                      newStart = s;
                      newEnd = e;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Abbrechen"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (newStart != null && newStart != event.startDate) {
                            vm.updateDate(newStart!, event.startDate);
                          }
                          if (newEnd != event.endDate) {
                            if (newEnd != null) {
                              vm.updateEndDate(newEnd!, event.endDate);
                            } else {
                              vm.clearEndDate(event.endDate);
                            }
                          }
                        },
                        child: const Text("Speichern"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildParticipantsTile(
    BuildContext context,
    EventOverviewViewModel vm,
    Event event,
  ) {
    return ListTile(
      leading: const Icon(Icons.people),
      title: Text("${event.participantCount} Teilnehmer"),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        // snippet aus deinem File
        showModalBottomSheet(
          context: context,
          builder:
              (_) => Padding(
                padding: const EdgeInsets.all(16),
                child:
                    vm.isParticipantsLoading
                        ? const Center(child: CircularProgressIndicator())
                        : vm.participantsError != null
                        ? Center(child: Text("Fehler: ${vm.participantsError}"))
                        : vm.participants.isEmpty
                        ? const Center(child: Text("Keine Teilnehmer."))
                        : ListView(
                          children:
                              vm.participants.map((p) {
                                return ListTile(
                                  leading: AvatarOrPlaceholder(
                                    imageUrl: p.photo,
                                    name: p.name,
                                  ),
                                  title: Text(p.name),
                                  subtitle: Text(p.role),
                                  onTap:
                                      vm.isOrganizer! &&
                                              p.uid !=
                                                  AuthService()
                                                      .currentUser()
                                                      ?.uid
                                          ? () async {
                                            // Auswahl-Dialog
                                            final choice = await showDialog<
                                              String
                                            >(
                                              context: context,
                                              builder:
                                                  (ctx) => SimpleDialog(
                                                    title: Text(
                                                      p.role == 'organizer'
                                                          ? 'Organisator verwalten'
                                                          : 'Teilnehmer verwalten',
                                                    ),
                                                    children: [
                                                      if (p.role != 'organizer')
                                                        SimpleDialogOption(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    ctx,
                                                                    'promote',
                                                                  ),
                                                          child: const Text(
                                                            'Zum Organisator machen',
                                                          ),
                                                        ),
                                                      if (p.role == 'organizer')
                                                        SimpleDialogOption(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    ctx,
                                                                    'demote',
                                                                  ),
                                                          child: const Text(
                                                            'Organisator-Status entfernen',
                                                          ),
                                                        ),
                                                      SimpleDialogOption(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              ctx,
                                                              'kick',
                                                            ),
                                                        child: const Text(
                                                          'Aus Event entfernen',
                                                        ),
                                                      ),
                                                      SimpleDialogOption(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              ctx,
                                                              null,
                                                            ),
                                                        child: const Text(
                                                          'Abbrechen',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );

                                            if (choice == 'promote') {
                                              await vm.promoteToOrganizer(
                                                p.uid,
                                              );
                                            } else if (choice == 'demote') {
                                              await vm.demoteFromOrganizer(
                                                p.uid,
                                              );
                                            } else if (choice == 'kick') {
                                              final confirm =
                                                  await showConfirmationDialog(
                                                    context,
                                                    'Teilnehmer entfernen',
                                                    'Willst du ${p.name} wirklich aus dem Event entfernen?',
                                                  );
                                              if (confirm) {
                                                await vm.kickParticipant(p.uid);
                                              }
                                            }
                                          }
                                          : null,
                                );
                              }).toList(),
                        ),
              ),
        );
      },
    );
  }

  Widget _buildAnnouncementsTile(BuildContext context) {
    final vm = context.read<EventOverviewViewModel>();
    return ListTile(
      leading: const Icon(Icons.announcement),
      title: const Text('Announcements'),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        context.push('/event-overview/${vm.event!.id}/announcements');
      },
    );
  }

  Widget _buildMap(
    BuildContext context,
    EventOverviewViewModel vm,
    Event event,
    bool isOrganizer,
  ) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          if (isOrganizer) {
            final choice = await showDialog<String>(
              context: context,
              builder:
                  (ctx) => SimpleDialog(
                    title: const Text("Karte"),
                    children: [
                      SimpleDialogOption(
                        onPressed: () => Navigator.of(ctx).pop('open'),
                        child: const Text("In Google Maps öffnen"),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.of(ctx).pop('edit'),
                        child: const Text("Ort bearbeiten"),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.of(ctx).pop(null),
                        child: const Text("Abbrechen"),
                      ),
                    ],
                  ),
            );

            if (choice == "open") {
              if (!context.mounted) return;
              _openGoogleMaps(context, event);
            } else if (choice == "edit") {
              if (!context.mounted) return;
              final newLoc = await Navigator.of(context).push<LatLng>(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => const MapPickerScreen(),
                ),
              );
              if (newLoc != null) {
                await vm.updateLocation(
                  newLoc,
                  LatLng(event.location.latitude, event.location.longitude),
                );
              }
            }
          } else {
            _openGoogleMaps(context, event);
          }
        },
        child: StaticMapSnippet(
          location: LatLng(event.location.latitude, event.location.longitude),
          width: 600,
          height: 150,
          zoom: 15,
        ),
      ),
    );
  }

  Widget _buildJoinLeaveButton(
    BuildContext context,
    EventOverviewViewModel vm,
    Event event,
    bool isParticipant,
  ) {
    final currentUser = AuthService().currentUser();
    return Center(
      child: ElevatedButton(
        onPressed:
            currentUser != null
                ? () => _toggleParticipation(
                  context,
                  isParticipant,
                  currentUser.uid,
                  event,
                )
                : null,
        child: Text(isParticipant ? "Event verlassen" : "Event beitreten"),
      ),
    );
  }

  Future<String?> _selectNewAdminDialog(
    BuildContext context,
    List<ParticipantProfile> candidates,
  ) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Neuen Admin auswählen"),
          content: SizedBox(
            height: 300,
            width: 300,
            child: ListView(
              children:
                  candidates
                      .map(
                        (p) => ListTile(
                          title: Text(p.name),
                          onTap: () => Navigator.of(dialogContext).pop(p.uid),
                        ),
                      )
                      .toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Abbrechen'),
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

    final isAdminUser = vm.participants.any(
      (p) => p.uid == userId && p.role == 'organizer',
    );

    if (isParticipant) {
      // User is attempting to leave the event
      if (isAdminUser) {
        final otherAdmins =
            vm.participants
                .where((p) => p.role == 'organizer' && p.uid != userId)
                .toList();
        final otherParticipants =
            vm.participants.where((p) => p.uid != userId).toList();

        if (otherAdmins.isNotEmpty) {
          // There are other admins, warn user will lose admin status
          final confirmed = await showConfirmationDialog(
            context,
            "Event verlassen",
            "Wenn du dieses Event verlässt, verlierst du deinen Admin-Status.",
          );
          if (!confirmed) return;
          // Proceed to leave normally below
        } else if (otherParticipants.isNotEmpty) {
          // User is the only admin, but there are other participants
          final assignConfirmed = await showConfirmationDialog(
            context,
            "Event verlassen",
            "Du bist der einzige Admin. Möchtest du einen anderen Teilnehmer zum Admin machen?",
          );
          if (!assignConfirmed) return;
          if (!context.mounted) return;
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
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fehler: Admin konnte nicht übertragen. ($e)'),
              ),
            );
            return;
          }
          // Now another admin exists, so current user can leave safely
          if (!context.mounted) return;
          final confirmed = await showConfirmationDialog(
            context,
            "Event verlassen",
            "Neuer Admin wurde ernannt. Möchtest du das Event jetzt verlassen?",
          );
          // If user decides not to leave after all (even after assigning), we might consider reverting the new admin,
          // but for simplicity we keep the new admin and just abort the leave.
          if (!confirmed) return;
          // Proceed to leave
        } else {
          // User is the last participant (and an admin)
          final confirmed = await showConfirmationDialog(
            context,
            "Event verlassen",
            "Du bist der letzte Teilnehmer. Wenn du gehst, wird das Event gelöscht.",
          );
          if (!confirmed) return;
          // Call Cloud Function to delete the event entirely
          try {
            await EventService().deleteEvent(event.id!);
            if (!context.mounted) return;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Event gelöscht")));
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Fehler beim Löschen des Events: $e')),
            );
          }
          return;
        }
      } else {
        // Normal participant (not admin) leaving
        final confirmed = await showConfirmationDialog(
          context,
          "Event verlassen",
          "Bist du sicher, dass du das Event verlassen willst?",
        );
        if (!confirmed) return;
      }

      try {
        await EventService().leaveEvent(event.id!, userId);
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Event verlassen")));
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fehler: Event konnte nicht verlassen werden. ($e)"),
          ),
        );
      }
    } else {
      // User is not a participant yet (joining the event)
      final confirmed = await showConfirmationDialog(
        context,
        "Event beitreten",
        "Möchtest du dich bei diesem Event eintragen?",
      );
      if (!confirmed) return;

      try {
        await EventService().joinEvent(event.id!, userId);
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Event beigetreten")));
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler: Konnte Event nicht beitreten. ($e)")),
        );
      }
    }
  }

  Future<void> _openGoogleMaps(BuildContext context, Event event) async {
    final lat = event.location.latitude;
    final lng = event.location.longitude;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Google Maps konnte nicht geöffnet werden"),
        ),
      );
    }
  }
}
