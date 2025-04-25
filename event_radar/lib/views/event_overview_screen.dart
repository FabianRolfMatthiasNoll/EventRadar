import 'package:event_radar/widgets/avatar_or_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/models/event.dart';
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

  Future<void> _toggleParticipation(
    BuildContext context,
    bool isParticipant,
    String userId,
    Event event,
  ) async {
    final title = isParticipant ? "Event verlassen" : "Event beitreten";
    final content =
        isParticipant
            ? "Bist du sicher, dass du das Event verlassen willst?"
            : "Möchtest du dich bei diesem Event eintragen?";
    final confirmed = await showConfirmationDialog(context, title, content);
    if (!confirmed) return;

    try {
      if (isParticipant) {
        await EventService().leaveEvent(event.id!, userId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Event verlassen")));
      } else {
        await EventService().joinEvent(event.id!, userId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Event beigetreten")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
