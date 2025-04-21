import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/models/event.dart';
import 'avatar_or_placeholder.dart';

class EventList extends StatelessWidget {
  final List<Event> events;
  final Position? userPosition;

  const EventList({
    super.key,
    required this.events,
    required this.userPosition,
  });

  String formatDateTime(DateTime dt) =>
      DateFormat('dd.MM.yyyy - HH:mm').format(dt);

  /// Build a subtitle that shows start date, and if applicable the end date
  /// and on a separate line the number of participiants and if the userPosition
  /// is available the distance in km
  String createInfoString(Event event) {
    StringBuffer infoBuffer = StringBuffer(formatDateTime(event.startDate));
    if (event.endDate != null) {
      infoBuffer.write(" bis ");
      infoBuffer.write(formatDateTime(event.endDate!));
    }

    infoBuffer.write("\n${event.participantCount} Teilnehmer");

    if (userPosition != null) {
      double distance =
          Geolocator.distanceBetween(
            userPosition!.latitude,
            userPosition!.longitude,
            event.location.latitude,
            event.location.longitude,
          ) /
          1000.0;
      infoBuffer.write(" • ${distance.toStringAsFixed(1)} km");
    }
    return infoBuffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return ListTile(
          leading: AvatarOrPlaceholder(
            imageUrl: event.image,
            name: event.title,
          ),
          title: Text(event.title),
          subtitle: Text(createInfoString(event)),
          onTap: () {
            context.push('/event-overview/${event.id}');
          },
        );
      },
    );
  }
}
