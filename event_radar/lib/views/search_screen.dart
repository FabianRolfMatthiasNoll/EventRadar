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
  int distance2 = 100;
  double sliderValue = 100;
  bool sliderEnabled = false;
  bool sliderEnabled2 = false;
  String distanceText = "";
  DateTime? startAfter;
  DateTime? startBefore;
  int? minParticipants;
  int? maxParticipants;
  TextEditingController distanceController = TextEditingController();
  TextEditingController distanceController2 = TextEditingController();
  final double sliderMin = 0.0;
  final double sliderMax = 300;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                Text('Umkreis: '),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      distanceController.text =
                          sliderEnabled ? distance.toString() : '∞';
                      return TextField(
                        controller: distanceController,
                        enabled: sliderEnabled,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          int? result = int.tryParse(value);
                          if (result == null) {
                            distanceController.text = value.replaceAll(
                              RegExp('\\D'),
                              '',
                            );
                          } else {
                            distance = result;
                            setState(() {
                              sliderValue = result.toDouble().clamp(
                                sliderMin,
                                sliderMax,
                              );
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
                Text(" km"),
                Checkbox(
                  value: sliderEnabled,
                  onChanged: (value) => setState(() => sliderEnabled = value!),
                ),
              ],
            ),
            subtitle: Slider(
              min: sliderMin,
              max: sliderMax,
              value: sliderValue,
              onChanged:
                  sliderEnabled
                      ? (double value) {
                        setState(() {
                          distance = value.toInt();
                          sliderValue = value;
                        });
                      }
                      : null,
            ),
          ),
          Divider(),
          Builder(
            builder: (context) {
              distanceController2.text =
                  sliderEnabled2 ? distance2.toString() : '∞';
              return SliderInput(
                value: distance2.toDouble(),
                onChanged: (value) {
                  setState(() {
                    distance2 = value.toInt();
                  });
                },
                onChangedNotParseable: (value) {
                  distanceController2.text = value.replaceAll(
                    RegExp('\\D'),
                    '',
                  );
                },
                textController: distanceController2,
                sliderMinValue: 0.0,
                sliderMaxValue: 300,
                enabled: sliderEnabled2,
                leading: [Text("Umkreis: ")],
                trailing: [
                  Text("km"),
                  Checkbox(
                    value: sliderEnabled2,
                    onChanged:
                        (value) => setState(() => sliderEnabled2 = value!),
                  ),
                ],
              );
            },
          ),
          Divider(),
          ListTile(
            onTap: () {},
            title: Text('Startet vor'),
            trailing: TextButton(
              onPressed: () {},
              child: Text(
                startAfter == null
                    ? 'Datum auswählen'
                    : formatDateTime(startAfter!),
              ),
            ),
          ),
          ListTile(
            onTap: () {},
            title: Text('Startet nach'),
            trailing: TextButton(
              onPressed: () {},
              child: Text(
                startAfter == null
                    ? 'Datum auswählen'
                    : formatDateTime(startAfter!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A Tile which contains a TextInput and a Slider.
class SliderInput extends StatelessWidget {
  final double value;

  /// Called when the Sliders onChanged is called or if a parsable double is input in the Textfield.
  final void Function(double) onChanged;

  /// Called when the the content of the Textfield changed to something not parseable to double.
  final void Function(String)? onChangedNotParseable;

  /// Min value of the slider. The actual value can still be lower if put in through the TextField.
  final double sliderMinValue;

  /// Max value of the slider. The actual value can still be lower if put in through the TextField.
  final double sliderMaxValue;
  final List<Widget> leading;
  final List<Widget> trailing;
  final bool enabled;
  final TextEditingController textController;

  const SliderInput({
    super.key,
    this.sliderMinValue = 0.0,
    this.sliderMaxValue = 1.0,
    required this.value,
    required this.onChanged,
    this.leading = const [],
    this.trailing = const [],
    this.enabled = true,
    required this.textController,
    this.onChangedNotParseable,
  });

  @override
  Widget build(BuildContext context) {
    double sliderValue = value.toDouble().clamp(sliderMinValue, sliderMaxValue);
    List<Widget> content = [];
    content.addAll(leading);
    content.add(
      Expanded(
        child: Builder(
          builder: (context) {
            return TextField(
              controller: textController,
              enabled: enabled,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                double? result = double.tryParse(value);
                if (result != null) {
                  onChanged(result);
                } else if (onChangedNotParseable != null) {
                  onChangedNotParseable!(value);
                }
              },
            );
          },
        ),
      ),
    );
    content.addAll(trailing);
    return ListTile(
      title: Row(children: content),
      subtitle: Slider(
        min: sliderMinValue,
        max: sliderMaxValue,
        value: sliderValue,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
