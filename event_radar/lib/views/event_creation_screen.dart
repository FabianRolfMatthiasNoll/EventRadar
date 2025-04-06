import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/viewmodels/event_creation_viewmodel.dart';
import 'map_picker_screen.dart';

class EventCreationScreen extends StatefulWidget {
  const EventCreationScreen({Key? key}) : super(key: key);

  @override
  _EventCreationScreenState createState() => _EventCreationScreenState();
}

class _EventCreationScreenState extends State<EventCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _selectDateTime(EventCreationViewModel viewModel) async {
    DateTime now = DateTime.now();
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date != null) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        viewModel.dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        setState(() {});
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Erstellung'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Erste Zeile: Kreis (Bild) links und Event Name rechts
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await viewModel.pickImage();
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: viewModel.imageFile != null
                          ? FileImage(viewModel.imageFile!)
                          : null,
                      child: viewModel.imageFile == null
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
              // Datum & Zeit auswählen
              Row(
                children: [
                  Expanded(
                    child: Text(viewModel.dateTime == null
                        ? 'Kein Datum ausgewählt'
                        : 'Datum: ${viewModel.dateTime!.toLocal().toString().substring(0, 16)}'),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDateTime(viewModel),
                    child: const Text('Datum wählen'),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              // Map Picker für den Ort
              Row(
                children: [
                  Expanded(
                    child: Text(viewModel.location == null
                        ? 'Kein Ort ausgewählt'
                        : 'Ort: Lat ${viewModel.location!.latitude}, Lng ${viewModel.location!.longitude}'),
                  ),
                  ElevatedButton(
                    onPressed: () => _pickLocation(viewModel),
                    child: const Text('Ort wählen'),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              // Beschreibung (optional)
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Beschreibung (optional)',
                ),
                maxLines: 3,
                onChanged: (value) => viewModel.description = value,
              ),
              const SizedBox(height: 16.0),
              // Radiobuttons für Sichtbarkeit
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
              const SizedBox(height: 16.0),
              // Button zum Erstellen des Events
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final message = await viewModel.createEvent();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
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
