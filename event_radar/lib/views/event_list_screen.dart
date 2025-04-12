import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/viewmodels/event_list_viewmodel.dart';
import '../core/models/event.dart';
import '../core/utils/initials_helper.dart';
import '../widgets/main_scaffold.dart';
import '../core/providers/location_provider.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({Key? key}) : super(key: key);

  Future<void> _refreshEvents(BuildContext context) async {
    await Provider.of<LocationProvider>(context, listen: false).updateLocation();
    await Provider.of<EventListViewModel>(context, listen: false).refreshEvents();
  }

  String formatDateTime(DateTime dt) => DateFormat('dd.MM.yyyy – HH:mm').format(dt);

  @override
  Widget build(BuildContext context) {
    final userPosition = Provider.of<LocationProvider>(context).currentPosition;

    return MainScaffold(
      title: 'Events',
      currentIndex: 0,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-event').then((_) {
            _refreshEvents(context);
          });
        },
        child: const Icon(Icons.add),
      ),
      showBackButton: false,
      body: Consumer<EventListViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => _refreshEvents(context),
            child: ListView.builder(
              itemCount: viewModel.events.length,
              itemBuilder: (context, index) {
                final Event event = viewModel.events[index];
                final double distance = userPosition != null
                    ? (Geolocator.distanceBetween(
                    userPosition.latitude,
                    userPosition.longitude,
                    event.location.latitude,
                    event.location.longitude) /
                    1000.0)
                    : 0.0;

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
                    backgroundImage: (event.image.isNotEmpty && event.image.startsWith('http'))
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
                    Navigator.pushNamed(
                      context,
                      '/event-overview',
                      arguments: event,
                    );
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
