import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/models/event.dart';
import '../core/viewmodels/event_list_viewmodel.dart';
import '../core/utils/initials_helper.dart';
import '../core/providers/location_provider.dart';
import '../widgets/main_scaffold.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  String formatDateTime(DateTime dt) =>
      DateFormat('dd.MM.yyyy – HH:mm').format(dt);

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final userPosition = locationProvider.currentPosition;

    if (userPosition == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MainScaffold(
      title: 'Meine Events',
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/event-list/create-event');
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Event>>(
        stream:
        Provider.of<EventListViewModel>(context, listen: false).userEventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Fehler: ${snapshot.error}"));
          }
          final events = snapshot.data;
          if (events == null || events.isEmpty) {
            return const Center(child: Text("Keine Events gefunden."));
          }
          return RefreshIndicator(
            onRefresh: () async {
              // Optionally update location here before refreshing, if needed.
              await locationProvider.updateLocation();
            },
            child: ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final double distance = Geolocator.distanceBetween(
                    userPosition.latitude,
                    userPosition.longitude,
                    event.location.latitude,
                    event.location.longitude) /
                    1000.0;
                // Build a subtitle that shows start date, and if applicable the end date on a separate line.
                Widget dateInfo;
                if (event.endDate != null) {
                  dateInfo = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${formatDateTime(event.startDate)} bis ${formatDateTime(event.endDate!)}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  );
                } else {
                  dateInfo = Text(
                    formatDateTime(event.startDate),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  );
                }
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (event.image.isNotEmpty &&
                        event.image.startsWith('http'))
                        ? NetworkImage(event.image)
                        : null,
                    child: (event.image.isEmpty || !event.image.startsWith('http'))
                        ? Text(getInitials(event.title))
                        : null,
                  ),
                  title: Text(event.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      dateInfo,
                      Text(
                        "${event.participantCount} Teilnehmer • ${distance.toStringAsFixed(1)} km",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () {
                    context.push('/event-overview/$index');
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
