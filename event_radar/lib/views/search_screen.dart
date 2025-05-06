import 'package:event_radar/core/util/date_time_format.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
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
  FilterOptions filter = FilterOptions();
  SortOption sort = SortOption.date;
  Position? userPosition;
  final searchController = TextEditingController();

  _SearchScreen() {
    _updateSearch();
    searchController.addListener(_updateSearch);
  }

  void _updateSearch() {
    EventService()
        .searchEvents(
          searchController.text,
          currentPosition: userPosition,
          sort: sort,
          filter: filter,
        )
        .then((result) => setState(() => events = result));
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    userPosition = Provider.of<LocationProvider>(context).currentPosition;

    return ListView.builder(
      itemCount: events.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return _searchAndFilterWidget();
        }
        return EventTile(event: events[index - 1], userPosition: userPosition);
      },
    );
  }

  Widget _sortOptionWidget(SortOption option) {
    switch (option) {
      case SortOption.date:
        return Text('Datum ');
      case SortOption.distance:
        return Text('Entfernung ');
      case SortOption.participantsAsc:
        return Row(
          children: [Text('Teilnehmer '), Icon(Icons.arrow_upward, size: 20)],
        );
      case SortOption.participantsDesc:
        return Row(
          children: [Text('Teilnehmer '), Icon(Icons.arrow_downward, size: 20)],
        );
    }
  }

  Widget _filterButtonText() {
    int amountFilter = 0;
    if (filter.distanceKilometers != null) {
      amountFilter++;
    }
    if (filter.startAfter != null) {
      amountFilter++;
    }
    if (filter.startBefore != null) {
      amountFilter++;
    }
    if (filter.minParticipants != null) {
      amountFilter++;
    }
    if (filter.maxParticipants != null) {
      amountFilter++;
    }
    return Text('Filter ($amountFilter)');
  }

  Widget _searchAndFilterWidget() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        spacing: 8,
        children: [
          SearchBar(
            controller: searchController,
            onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            trailing: [
              searchController.text != ''
                  ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      searchController.text = '';
                    },
                  )
                  : SizedBox.shrink(),
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ],
          ),
          Row(
            spacing: 8,
            children: [
              Text('Sortierung:'),
              DropdownButton(
                value: sort,
                items:
                    SortOption.values.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: _sortOptionWidget(option),
                      );
                    }).toList(),
                onChanged: (option) {
                  if (option != null) {
                    setState(() {
                      sort = option;
                    });
                    _updateSearch();
                  }
                },
              ),
              ElevatedButton(
                onPressed: () => _showFilterSheet(context),
                child: Row(
                  spacing: 8,
                  children: [Icon(Icons.filter_alt), _filterButtonText()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    FilterOptions? newFilter = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterOptionsSelection(filter: filter),
    );
    if (newFilter != null) {
      setState(() {
        filter = newFilter;
      });
      _updateSearch();
    }
  }
}

class FilterOptionsSelection extends StatefulWidget {
  final FilterOptions filter;
  const FilterOptionsSelection({super.key, required this.filter});

  @override
  State<StatefulWidget> createState() {
    return _FilterOptionsSelectionState();
  }
}

class _FilterOptionsSelectionState extends State<FilterOptionsSelection> {
  late int distance = widget.filter.distanceKilometers ?? 150;
  final double sliderMin = 0.0;
  final double sliderMax = 300;
  late bool sliderEnabled = widget.filter.distanceKilometers != null;
  TextEditingController distanceController = TextEditingController();

  late DateTime? startAfter = widget.filter.startAfter;
  late DateTime? endBefore = widget.filter.startBefore;

  late int? minParticipants = widget.filter.minParticipants;
  late int? maxParticipants = widget.filter.maxParticipants;
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
  void dispose() {
    distanceController.dispose();
    minParticipantsController.dispose();
    maxParticipantsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    distanceController.text = sliderEnabled ? distance.toString() : '∞';
    minParticipantsController.text = minParticipants?.toString() ?? '';
    maxParticipantsController.text = maxParticipants?.toString() ?? '';

    return Padding(
      padding: EdgeInsets.all(16),
      // Scrollable in case the screen is too small
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              title: Text('Beginnt vor'),
            ),
            Divider(),
            IntegerInputTile(
              title: Text('Min Teilnehmer'),
              value: minParticipants,
              onValueChanged: (value) {
                if (value == null || value >= 0) {
                  setState(() => minParticipants = value);
                }
              },
              controller: minParticipantsController,
            ),
            IntegerInputTile(
              title: Text('Max Teilnehmer'),
              value: maxParticipants,
              onValueChanged: (value) {
                if (value == null || value >= 0) {
                  setState(() => maxParticipants = value);
                }
              },
              controller: maxParticipantsController,
            ),
            SizedBox(height: 16),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    child: Text('Abbrechen'),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      context.pop(
                        FilterOptions(
                          distanceKilometers: sliderEnabled ? distance : null,
                          startAfter: startAfter,
                          startBefore: endBefore,
                          minParticipants: minParticipants,
                          maxParticipants: maxParticipants,
                        ),
                      );
                    },
                    child: Text('Anwenden'),
                  ),
                ),
              ],
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
    DateTime now = DateTime.now();
    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
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
  final int? value;
  final void Function(int?) onValueChanged;
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
              int temp = value ?? 0;
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
                onValueChanged(int.tryParse(controller.text));
              },
            ),
          ),
          IconButton(
            onPressed: () {
              int temp = value ?? 0;
              onValueChanged(temp + 1);
            },
            icon: Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
