import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_service.dart';

class EventMapViewModel extends ChangeNotifier {
  final EventService _eventService = EventService();
  List<Event> events = [];
  bool isLoading = false;

  EventMapViewModel() {
    fetchPublicEvents();
  }

  Future<void> fetchPublicEvents() async {
    isLoading = true;
    notifyListeners();
    try {
      List<Event> allEvents = await _eventService.getEvents();
      events = allEvents.where((event) => event.visibility == 'public').toList();
    } catch (e) {
      print("Error fetching events for map: $e");
    }
    isLoading = false;
    notifyListeners();
  }
}
