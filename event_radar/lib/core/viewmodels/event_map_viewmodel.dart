import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_service.dart';

class EventMapViewModel extends ChangeNotifier {
  final EventService _eventService = EventService();
  List<Event> publicEvents = [];
  bool isLoading = false;

  EventMapViewModel() {
    fetchPublicEvents();
  }

  Future<void> fetchPublicEvents() async {
    isLoading = true;
    notifyListeners();
    try {
      publicEvents = await _eventService.getPublicEvents();
    } catch (e) {
      print("Error fetching events for map: $e");
    }
    isLoading = false;
    notifyListeners();
  }
}
