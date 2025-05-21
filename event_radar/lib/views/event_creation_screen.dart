import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/util/text_utils.dart';
import 'package:event_radar/widgets/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/viewmodels/event_creation_viewmodel.dart';
import '../widgets/date_time_picker.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/static_map_snippet.dart';
import 'map_picker_screen.dart';

class EventCreationScreen extends StatefulWidget {
  const EventCreationScreen({super.key});

  @override
  State<EventCreationScreen> createState() => _EventCreationScreenState();
}

class _EventCreationScreenState extends State<EventCreationScreen> {
  final _formKey = GlobalKey<FormState>();

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
    final vm = Provider.of<EventCreationViewModel>(context);

    vm.dateTime ??= DateTime.now();

    // Calculate the available map width based on screen size and padding.
    final double mapWidth =
        MediaQuery.of(context).size.width - 32; // 16 px padding each side

    return MainScaffold(
      title: 'Event Erstellung',
      body:
          vm.isLoading
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
                              final file = await pickAndCropImage();
                              setState(() {
                                vm.imageFile = file;
                              });
                            },
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[300],
                              backgroundImage:
                                  vm.imageFile != null
                                      ? FileImage(vm.imageFile!)
                                      : (vm.imageUrl != null &&
                                          vm.imageUrl!.startsWith('http'))
                                      ? NetworkImage(vm.imageUrl!)
                                          as ImageProvider
                                      : null,
                              child:
                                  vm.imageFile == null &&
                                          (vm.imageUrl == null ||
                                              !vm.imageUrl!.startsWith('http'))
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
                              maxLength: Event.maxTitleLength,
                              onChanged: (value) => vm.title = value,
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
                      DateTimePicker(
                        label: 'Start:',
                        initialStart: vm.dateTime!,
                        initialEnd: vm.endDateTime,
                        onChanged:
                            (newStart, newEnd) => setState(() {
                              vm.dateTime = newStart;
                              vm.endDateTime = newEnd;
                            }),
                      ),
                      const SizedBox(height: 16.0),
                      // Location picker
                      InkWell(
                        onTap: () => _pickLocation(vm),
                        child: Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child:
                              vm.location != null
                                  ? StaticMapSnippet(
                                    location: vm.location!,
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
                        maxLength: Event.maxDescriptionLength,
                        minLines: 1,
                        maxLines: 5,
                        onChanged: (value) {
                          vm.description = cleanString(value);
                        },
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
                              groupValue: vm.visibility,
                              onChanged: (value) {
                                vm.visibility = value!;
                                setState(() {});
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Invite-only'),
                              value: 'invite-only',
                              groupValue: vm.visibility,
                              onChanged: (value) {
                                vm.visibility = value!;
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
                            value: vm.promoted,
                            onChanged: (bool newValue) {
                              vm.promoted = newValue;
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
                            final message = await vm.createEvent();
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
