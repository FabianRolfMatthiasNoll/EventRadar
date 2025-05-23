import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../core/models/event.dart';
import '../core/util/date_time_format.dart';
import 'avatar_or_placeholder.dart';

class EventTile extends StatelessWidget {
  final Event event;
  final Position? userPosition;
  final bool isPromoted;

  const EventTile({
    super.key,
    required this.event,
    required this.userPosition,
    this.isPromoted = false,
  });

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
    final container = Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow:
            isPromoted
                ? [
                  BoxShadow(
                    color: const Color.fromARGB(255, 255, 212, 121),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
                : [],
      ),
      child: ListTile(
        leading: Stack(
          alignment: Alignment.topRight,
          children: [
            AvatarOrPlaceholder(imageUrl: event.image, name: event.title),
            if (isPromoted)
              const Icon(Icons.star, color: Colors.amber, size: 18),
          ],
        ),
        title: Text(
          event.title,
          style: TextStyle(color: isPromoted ? Colors.orange[900] : null),
        ),
        subtitle: Text(createInfoString(event)),
        onTap: () => context.push('/event-overview/${event.id}'),
      ),
    );
    final card = Card(
      shadowColor:
          isPromoted
              ? Color.fromARGB(255, 255, 212, 121)
              : Theme.of(context).shadowColor,
      elevation: isPromoted ? 3 : 1,
      color: isPromoted ? Colors.amber.shade50 : Theme.of(context).cardColor,
      child: ListTile(
        leading: Stack(
          alignment: Alignment.topRight,
          children: [
            AvatarOrPlaceholder(imageUrl: event.image, name: event.title),
            if (isPromoted)
              const Icon(Icons.star, color: Colors.amber, size: 18),
          ],
        ),
        title: Text(
          event.title,
          style: TextStyle(color: isPromoted ? Colors.orange[900] : null),
        ),
        subtitle: Text(createInfoString(event)),
        onTap: () => context.push('/event-overview/${event.id}'),
      ),
    );
    return card;
  }
}
