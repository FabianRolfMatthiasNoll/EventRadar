import 'package:event_radar/core/util/date_time_format.dart';
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
            onSubmitted: (search) {},
            trailing: [
              IconButton(icon: Icon(Icons.clear), onPressed: () {}),
              IconButton(icon: Icon(Icons.search), onPressed: () {}),
            ],
          ),
          Row(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => _showFilterSheet(context),
                child: Row(
                  spacing: 8,
                  children: [Icon(Icons.filter_alt), Text('Filter')],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                child: Row(
                  spacing: 8,
                  children: [Icon(Icons.sort), Text('Sort')],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => FilterOptionsSelection(),
    );
  }
}

class FilterOptionsSelection extends StatefulWidget {
  const FilterOptionsSelection({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FilterOptionsSelectionState();
  }
}

class _FilterOptionsSelectionState extends State<FilterOptionsSelection> {
  int distance = 100;
  final double sliderMin = 0.0;
  final double sliderMax = 300;
  bool sliderEnabled = false;
  TextEditingController distanceController = TextEditingController();

  DateTime? startAfter;
  DateTime? endBefore;

  int minParticipants = 0;
  int maxParticipants = 500;
  TextEditingController minParticipantsController = TextEditingController();
  TextEditingController maxParticipantsController = TextEditingController();

  void _distanceTextUpdated(String input) {
    int? result = int.tryParse(input);
    if (result == null) {
      distanceController.text = input.replaceAll(RegExp(r'\D'), '');
    } else {
      setState(() {
        distance = result;
      });
    }
  }

  void _updateDistance(double value) {
    setState(() {
      distance = value.toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    distanceController.text = sliderEnabled ? distance.toString() : '∞';
    minParticipantsController.text = minParticipants.toString();
    maxParticipantsController.text = maxParticipants.toString();

    return Padding(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Row(
                children: [
                  // Slider connected with TextField
                  Text('Umkreis: '),
                  Expanded(
                    child: TextField(
                      controller: distanceController,
                      enabled: sliderEnabled,
                      keyboardType: TextInputType.number,
                      onChanged: _distanceTextUpdated,
                    ),
                  ),
                  Text(" km"),
                  Checkbox(
                    value: sliderEnabled,
                    onChanged:
                        (value) => setState(() => sliderEnabled = value!),
                  ),
                ],
              ),
              subtitle: Slider(
                min: sliderMin,
                max: sliderMax,
                value: distance.toDouble().clamp(sliderMin, sliderMax),
                onChanged: sliderEnabled ? _updateDistance : null,
              ),
            ),
            Divider(),
            DateSelectionTile(
              date: startAfter,
              onChanged: (value) => setState(() => startAfter = value),
              title: Text('Startet nach'),
            ),
            DateSelectionTile(
              date: endBefore,
              onChanged: (value) => setState(() => endBefore = value),
              title: Text('Endet vor'),
            ),
            Divider(),
            IntegerInputTile(
              title: Text('Min Teilnehmer'),
              value: minParticipants,
              onValueChanged:
                  (value) => setState(() => minParticipants = value),
              controller: minParticipantsController,
            ),
            IntegerInputTile(
              title: Text('Max Teilnehmer'),
              value: maxParticipants,
              onValueChanged:
                  (value) => setState(() => maxParticipants = value),
              controller: maxParticipantsController,
            ),
          ],
        ),
      ),
    );
  }
}

class DateSelectionTile extends StatelessWidget {
  final DateTime? date;
  final void Function(DateTime?) onChanged;
  final Widget? title;
  const DateSelectionTile({
    super.key,
    required this.date,
    required this.onChanged,
    this.title,
  });

  Future<void> _pickDate(BuildContext context) async {
    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (newDate != null) {
      onChanged(newDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Expanded(child: title ?? SizedBox.shrink()),
          TextButton(
            onPressed: () => _pickDate(context),
            child: Text(date == null ? 'Datum auswählen' : formatDate(date!)),
          ),
          date == null
              ? SizedBox.shrink()
              : IconButton(
                onPressed: () => onChanged(null),
                icon: Icon(
                  Icons.backspace_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
        ],
      ),
    );
  }
}

class IntegerInputTile extends StatelessWidget {
  final int value;
  final void Function(int) onValueChanged;
  final TextEditingController controller;
  final Widget? title;
  const IntegerInputTile({
    super.key,
    required this.value,
    required this.onValueChanged,
    required this.controller,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Expanded(child: title ?? SizedBox.shrink()),
          IconButton(
            onPressed: () {
              int temp = value;
              onValueChanged(temp - 1);
            },
            icon: Icon(Icons.remove),
          ),
          SizedBox(
            width: 48,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              onChanged: (input) {
                controller.text = input.replaceAll(RegExp(r'\D'), '');
                onValueChanged(int.tryParse(controller.text) ?? 0);
              },
            ),
          ),
          IconButton(
            onPressed: () {
              int temp = value;
              onValueChanged(temp + 1);
            },
            icon: Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
