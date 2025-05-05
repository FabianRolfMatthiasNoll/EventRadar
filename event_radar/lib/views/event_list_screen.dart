import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/models/event.dart';
import '../core/viewmodels/event_list_viewmodel.dart';
import '../core/providers/location_provider.dart';
import '../widgets/event_tile.dart';
import '../widgets/main_scaffold.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

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
              itemBuilder: (BuildContext context, int index) {
                return EventTile(
                  event: events[index],
                  userPosition: userPosition,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
