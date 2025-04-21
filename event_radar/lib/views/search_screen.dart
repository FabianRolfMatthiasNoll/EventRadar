import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/event.dart';
import '../core/providers/location_provider.dart';
import '../core/services/event_service.dart';
import '../widgets/event_list.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SearchScreen();
  }

}

class _SearchScreen extends State<SearchScreen> {
  List<Event> events = [];

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final userPosition = locationProvider.currentPosition;

    EventService().searchEvents().then((result) => setState(() => events = result));
    return EventList(events: events, userPosition: userPosition);
  }

}
