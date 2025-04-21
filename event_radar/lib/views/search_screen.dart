import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/event.dart';
import '../core/providers/location_provider.dart';
import '../core/services/event_service.dart';
import '../widgets/event_tile.dart';

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

    EventService().searchEvents().then(
      (result) => setState(() => events = result),
    );
    return ListView.builder(
      itemCount: events.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return searchAndFilterWidget();
        }
        return EventTile(event: events[index - 1], userPosition: userPosition);
      },
    );
  }

  Widget searchAndFilterWidget() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        spacing: 8,
        children: [
          SearchBar(
            onSubmitted: (search) { },
            trailing: [
              IconButton(icon: Icon(Icons.clear), onPressed: () {  }),
              IconButton(icon: Icon(Icons.search), onPressed: () {  }),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                Chip(label: Text("Umkreis 3 km")),
                Chip(label: Text("von 20.02.2025")),
                Chip(label: Text("bis 06.06.2025")),
                Chip(label: Text("min 5 Teilnehmer")),
                Chip(label: Text("max 5 Teilnehmer")),
              ],
            ),
          )
        ],
      ),
    );
  }
}
