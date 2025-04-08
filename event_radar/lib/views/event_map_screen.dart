import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../core/providers/location_provider.dart';
import '../core/viewmodels/event_map_viewmodel.dart';
import '../core/models/event.dart';
import '../core/utils/initials_helper.dart';

class EventMapScreen extends StatelessWidget {
  const EventMapScreen({super.key});

  Set<Marker> _createMarkers(List<Event> events, BuildContext context) {
    return events.map((event) {
      return Marker(
        markerId: MarkerId(event.id ?? event.title),
        position: LatLng(event.location.latitude, event.location.longitude),
        // TODO: Make a custom marker to have logo. If no logo is there then normal marker
        // TODO: Make custom cool markers for promoted events
        icon: BitmapDescriptor.defaultMarkerWithHue(
            event.promoted ? BitmapDescriptor.hueYellow : BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: event.title,
          snippet: event.description ?? '',
          onTap: () => _showEventDetails(context, event),
        ),
      );
    }).toSet();
  }

  void _showEventDetails(BuildContext context, Event event) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: (event.image.isNotEmpty && event.image.startsWith('http'))
                    ? NetworkImage(event.image)
                    : null,
                child: (event.image.isEmpty || !event.image.startsWith('http'))
                    ? Text(getInitials(event.title))
                    : null,
              ),
              title: Text(event.title),
              subtitle: Text(event.description ?? 'Keine Beschreibung vorhanden'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/event-overview', arguments: event);
              },
              child: const Text("Zum Event"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the global user location from LocationProvider.
    final userPosition = Provider.of<LocationProvider>(context).currentPosition;

    // If the location isn’t yet available, show a loader.
    if (userPosition == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Event Map'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Use the EventMapViewModel to get event data.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<EventMapViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(userPosition.latitude, userPosition.longitude),
              zoom: 15,
            ),
            markers: _createMarkers(viewModel.events, context),
            myLocationEnabled: true,
            zoomControlsEnabled: true,
            onMapCreated: (controller) {},
          );
        },
      ),
    );
  }
}
