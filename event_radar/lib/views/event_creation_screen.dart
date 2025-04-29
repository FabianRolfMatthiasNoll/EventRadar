import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/utils/image_picker.dart';
import '../core/viewmodels/event_creation_viewmodel.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/static_map_snippet.dart';
import 'map_picker_screen.dart';

class EventCreationScreen extends StatefulWidget {
  const EventCreationScreen({Key? key}) : super(key: key);

  @override
  _EventCreationScreenState createState() => _EventCreationScreenState();
}

class _EventCreationScreenState extends State<EventCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Formatters.
  String formatDate(DateTime date) => DateFormat('dd.MM.yyyy').format(date);
  String formatTime(DateTime date) => DateFormat('HH:mm').format(date);

  Widget _buildDateTimeRow({
    required String label,
    required DateTime dateTime,
    required VoidCallback onSelectDate,
    required VoidCallback onSelectTime,
    Widget? removeWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Fixed width label.
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        // Date picker part.
        Expanded(
          child: InkWell(
            onTap: onSelectDate,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.date_range),
                  const SizedBox(width: 4.0),
                  Text(formatDate(dateTime)),
                ],
              ),
            ),
          ),
        ),
        // Time picker part.
        Expanded(
          child: InkWell(
            onTap: onSelectTime,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.access_time),
                  const SizedBox(width: 4.0),
                  Text(formatTime(dateTime)),
                ],
              ),
            ),
          ),
        ),
        // Reserve a fixed width space for the remove icon (if not provided, leave empty for proper alignment)
        SizedBox(width: 40, child: removeWidget ?? const SizedBox.shrink()),
      ],
    );
  }

  Future<void> _selectStartDate(EventCreationViewModel viewModel) async {
    DateTime initial = viewModel.dateTime ?? DateTime.now();
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      viewModel.dateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        viewModel.dateTime?.hour ?? initial.hour,
        viewModel.dateTime?.minute ?? initial.minute,
      );
      setState(() {});
    }
  }

  Future<void> _selectStartTime(EventCreationViewModel viewModel) async {
    DateTime initial = viewModel.dateTime ?? DateTime.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (picked != null) {
      viewModel.dateTime = DateTime(
        initial.year,
        initial.month,
        initial.day,
        picked.hour,
        picked.minute,
      );
      setState(() {});
    }
  }

  Future<void> _selectEndDate(EventCreationViewModel viewModel) async {
    DateTime initial =
        viewModel.endDateTime ?? (viewModel.dateTime ?? DateTime.now());
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: viewModel.dateTime ?? DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) {
      viewModel.endDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        viewModel.endDateTime?.hour ?? initial.hour,
        viewModel.endDateTime?.minute ?? initial.minute,
      );
      setState(() {});
    }
  }

  Future<void> _selectEndTime(EventCreationViewModel viewModel) async {
    DateTime initial =
        viewModel.endDateTime ?? (viewModel.dateTime ?? DateTime.now());
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (picked != null) {
      viewModel.endDateTime = DateTime(
        initial.year,
        initial.month,
        initial.day,
        picked.hour,
        picked.minute,
      );
      setState(() {});
    }
  }

  Future<void> _pickLocation(EventCreationViewModel viewModel) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );
    if (result != null) {
      viewModel.location = result;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<EventCreationViewModel>(context);

    // Prepopulate with current time if not already set.
    viewModel.dateTime ??= DateTime.now();

    // Calculate the available map width based on screen size and padding.
    final double mapWidth =
        MediaQuery.of(context).size.width - 32; // 16 px padding each side

    return MainScaffold(
      title: 'Event Erstellung',
      body:
          viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Image picker and event name.
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              viewModel.imageFile = await pickAndCropImage();
                            },
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[300],
                              backgroundImage:
                                  viewModel.imageFile != null
                                      ? FileImage(viewModel.imageFile!)
                                      : (viewModel.imageUrl != null &&
                                          viewModel.imageUrl!.startsWith(
                                            'http',
                                          ))
                                      ? NetworkImage(viewModel.imageUrl!)
                                          as ImageProvider
                                      : null,
                              child:
                                  viewModel.imageFile == null &&
                                          (viewModel.imageUrl == null ||
                                              !viewModel.imageUrl!.startsWith(
                                                'http',
                                              ))
                                      ? Text(
                                        "Foto\nhochladen",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      )
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Event Name',
                              ),
                              onChanged: (value) => viewModel.title = value,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Bitte geben Sie einen Event Namen ein';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      // Start date and time row.
                      _buildDateTimeRow(
                        label: "Start:",
                        dateTime: viewModel.dateTime!,
                        onSelectDate: () => _selectStartDate(viewModel),
                        onSelectTime: () => _selectStartTime(viewModel),
                        removeWidget: null, // No remove option for start time.
                      ),
                      const SizedBox(height: 16.0),
                      // End date and time row.
                      viewModel.endDateTime != null
                          ? _buildDateTimeRow(
                            label: "Ende:",
                            dateTime: viewModel.endDateTime!,
                            onSelectDate: () => _selectEndDate(viewModel),
                            onSelectTime: () => _selectEndTime(viewModel),
                            removeWidget: IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              tooltip: "Endzeit entfernen",
                              onPressed: () {
                                setState(() {
                                  viewModel.endDateTime = null;
                                });
                              },
                            ),
                          )
                          : Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Endzeit hinzufügen'),
                              onPressed: () {
                                setState(() {
                                  viewModel.endDateTime = viewModel.dateTime!
                                      .add(const Duration(hours: 1));
                                });
                              },
                            ),
                          ),
                      const SizedBox(height: 16.0),
                      // Location picker
                      InkWell(
                        onTap: () => _pickLocation(viewModel),
                        child: Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child:
                              viewModel.location != null
                                  ? StaticMapSnippet(
                                    location: viewModel.location!,
                                    width: mapWidth.toInt(),
                                    height: 150,
                                    zoom: 15,
                                  )
                                  : const Center(
                                    child: Text(
                                      'Tippe hier um einen Ort auszuwählen',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                        ),
                      ),
                      // Description field.
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Beschreibung (optional)',
                        ),
                        maxLines: 3,
                        onChanged: (value) => viewModel.description = value,
                      ),
                      const SizedBox(height: 16.0),
                      // Visibility selection.
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Sichtbarkeit:'),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Öffentlich'),
                              value: 'public',
                              groupValue: viewModel.visibility,
                              onChanged: (value) {
                                viewModel.visibility = value!;
                                setState(() {});
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Invite-only'),
                              value: 'invite-only',
                              groupValue: viewModel.visibility,
                              onChanged: (value) {
                                viewModel.visibility = value!;
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      // Promotion switch.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Event promoten'),
                          Switch(
                            value: viewModel.promoted,
                            onChanged: (bool newValue) {
                              viewModel.promoted = newValue;
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      // Create event button.
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final message = await viewModel.createEvent();
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(message)));
                            if (message == 'Event erfolgreich erstellt') {
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: const Text('Event erstellen'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
