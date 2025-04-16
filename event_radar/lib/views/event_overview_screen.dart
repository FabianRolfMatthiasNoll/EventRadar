import 'package:event_radar/core/utils/image_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/event.dart';
import '../core/services/auth_service.dart';
import '../core/services/event_service.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/static_map_snippet.dart';

class EventOverviewScreen extends StatelessWidget {
  final String eventId;

  const EventOverviewScreen({super.key, required this.eventId});

  Future<bool> _showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: const Text("Abbrechen"),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text("Bestätigen"),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _toggleParticipation(
    BuildContext context,
    bool isParticipant,
    String userId,
    Event event,
  ) async {
    final confirmTitle = isParticipant ? "Event verlassen" : "Event beitreten";
    final confirmContent =
        isParticipant
            ? "Bist du sicher das du das Event verlassen willst?"
            : "Möchtest du dich bei diesem Event eintragen?";
    final confirmed = await _showConfirmationDialog(
      context,
      confirmTitle,
      confirmContent,
    );
    if (!confirmed) return;

    try {
      if (isParticipant) {
        await EventService().leaveEvent(event.id!, userId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Event verlassen")));
      } else {
        await EventService().joinEvent(event.id!, userId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Event beigetreten")));
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
    final Uri googleUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Maps konnte nicht geöffnet werden'),
        ),
      );
    }
  }

  String formatDateTime(DateTime dt) {
    return DateFormat('dd.MM.yyyy – HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve the current user (synchronously from FirebaseAuth)
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
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text("Fehler beim Laden des Events"));
          }
          final Event event = snapshot.data!;
          // Determine if the current user is a participant based on event data.
          final bool isParticipant =
              currentUser != null &&
              event.participants.contains(currentUser.uid);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: event image and name.
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          (event.image.isNotEmpty &&
                                  event.image.startsWith('http'))
                              ? NetworkImage(event.image)
                              : null,
                      child:
                          (event.image.isEmpty ||
                                  !event.image.startsWith('http'))
                              ? Text(getImagePlaceholder(event.title))
                              : null,
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
                              Text("End: ${formatDateTime(event.endDate!)}"),
                            ],
                          )
                          : Text(formatDateTime(event.startDate)),
                ),
                // Participants.
                ListTile(
                  leading: const Icon(Icons.people),
                  title: Text("${event.participantCount} participants"),
                ),
                // Announcements.
                if (isParticipant)
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
                // Join/Leave button.
                Center(
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
                    child: Text(
                      isParticipant ? "Event verlassen" : "Event beitreten",
                    ),
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
