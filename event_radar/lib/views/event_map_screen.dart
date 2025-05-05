import 'package:collection/collection.dart';
import 'package:event_radar/widgets/avatar_or_placeholder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../core/models/event.dart';
import '../core/providers/location_provider.dart';
import '../core/viewmodels/event_map_viewmodel.dart';

class EventMapScreen extends StatelessWidget {
  const EventMapScreen({super.key});

  Set<Marker> _createMarkers(List<Event> events, BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return events.mapIndexed((index, event) {
      final isMember = uid != null && event.participants.contains(uid);
      final hue =
          isMember
              ? BitmapDescriptor.hueGreen
              : event.promoted
              ? BitmapDescriptor.hueYellow
              : BitmapDescriptor.hueBlue;

      return Marker(
        markerId: MarkerId(event.id ?? event.title),
        position: LatLng(event.location.latitude, event.location.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        onTap: () => _showEventDetails(context, event, index),
      );
    }).toSet();
  }

  void _showEventDetails(BuildContext context, Event event, int index) {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: AvatarOrPlaceholder(
                    imageUrl: event.image,
                    name: event.title,
                  ),
                  title: Text(event.title),
                  subtitle: Text(
                    event.description ?? "Keine Beschreibung vorhanden",
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.push("/event-overview/${event.id}"),
                  child: const Text("Zum Event"),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userPosition = Provider.of<LocationProvider>(context).currentPosition;

    if (userPosition == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Consumer<EventMapViewModel>(
        builder: (context, viewModel, _) {
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
          );
        },
      ),
    );
  }
}
