import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/event.dart';
import '../core/utils/initials_helper.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/static_map_snippet.dart';

class EventOverviewScreen extends StatelessWidget {
  final Event event;
  final bool isParticipant;

  const EventOverviewScreen({
    Key? key,
    required this.event,
    this.isParticipant = true,
  }) : super(key: key);

  Future<void> _openGoogleMaps(BuildContext context) async {
    final lat = event.location.latitude;
    final lng = event.location.longitude;
    final Uri googleUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  String formatDateTime(DateTime dt) {
    return DateFormat('dd.MM.yyyy – HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: event image and name.
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: (event.image.isNotEmpty && event.image.startsWith('http'))
                      ? NetworkImage(event.image)
                      : null,
                  child: (event.image.isEmpty || !event.image.startsWith('http'))
                      ? Text(getInitials(event.title))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
            // Date/time display: if an end date exists, show start and end on separate rows.
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: event.endDate != null
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Start: ${formatDateTime(event.startDate)}"),
                  const SizedBox(height: 4),
                  Text("Ende: ${formatDateTime(event.endDate!)}"),
                ],
              )
                  : Text(formatDateTime(event.startDate)),
            ),
            // Participants.
            ListTile(
              leading: const Icon(Icons.people),
              title: Text("${event.participantCount} Teilnehmer"),
            ),
            // Announcements.
            ListTile(
              leading: const Icon(Icons.announcement),
              title: const Text("Ankündigungen"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to announcements.
              },
            ),
            const SizedBox(height: 16),
            // Location snippet.
            GestureDetector(
              onTap: () => _openGoogleMaps(context),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.antiAlias,
                child: StaticMapSnippet(
                  location: LatLng(event.location.latitude, event.location.longitude),
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
                onPressed: () {
                  // TODO: Implement join/leave logic.
                },
                child: Text(isParticipant ? "Event verlassen" : "Event beitreten"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
