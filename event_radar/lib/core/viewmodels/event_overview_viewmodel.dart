import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/event.dart';
import '../models/participant.dart';
import '../services/event_service.dart';
import '../services/participant_service.dart';

class EventOverviewViewModel extends ChangeNotifier {
  final String eventId;
  final EventService _eventService = EventService();

  List<ParticipantProfile> participants = [];
  bool isLoading = false;
  String? error;

  Event? event;
  bool isEventLoading = true;
  String? eventError;

  late final StreamSubscription<Event> _eventStreamSub;

  EventOverviewViewModel(this.eventId) {
    _loadParticipants();
    _eventStreamSub = _eventService
        .getEventStream(eventId)
        .listen(_handleEventData, onError: _handleEventError);
  }

  void _handleEventData(Event evt) {
    event = evt;
    isEventLoading = false;
    notifyListeners();
    _loadParticipants();
  }

  void _handleEventError(Object e) {
    eventError = e.toString();
    isEventLoading = false;
    notifyListeners();
  }

  Future<void> _loadParticipants() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      participants = await ParticipantService.fetch(eventId);
    } catch (e) {
      participants = [];
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTitle(String newTitle, String oldTitle) async {
    await _eventService.updateEvent(eventId, {'title': newTitle});
    await _eventService.logEventChange(eventId, {
      'type': 'title_change',
      'oldValue': oldTitle,
      'newValue': newTitle,
    });
  }

  Future<void> updateDescription(String newDesc, String oldDesc) async {
    await _eventService.updateEvent(eventId, {'description': newDesc});
    await _eventService.logEventChange(eventId, {
      'type': 'description_change',
      'oldValue': oldDesc,
      'newValue': newDesc,
    });
  }

  Future<void> updateDate(DateTime newDate, DateTime oldDate) async {
    await _eventService.updateEvent(eventId, {'date': newDate});
    await _eventService.logEventChange(eventId, {
      'type': 'date_change',
      'oldValue': oldDate.toIso8601String(),
      'newValue': newDate.toIso8601String(),
    });
  }

  Future<void> updateEndDate(DateTime newEnd, DateTime? oldEnd) async {
    await _eventService.updateEvent(eventId, {'endDate': newEnd});
    await _eventService.logEventChange(eventId, {
      'type': 'end_date_change',
      'oldValue': oldEnd?.toIso8601String(),
      'newValue': newEnd.toIso8601String(),
    });
  }

  Future<void> updateImage(String newUrl, String oldUrl) async {
    await _eventService.updateEvent(eventId, {'image': newUrl});
    await _eventService.logEventChange(eventId, {
      'type': 'image_change',
      'oldValue': oldUrl,
      'newValue': newUrl,
    });
    // TODO: Delete old image upon update
  }

  Future<void> updateLocation(LatLng newLoc, LatLng oldLoc) async {
    final geo = GeoPoint(newLoc.latitude, newLoc.longitude);
    await _eventService.updateEvent(eventId, {'location': geo});
    await _eventService.logEventChange(eventId, {
      'type': 'location_change',
      'oldValue': '${oldLoc.latitude},${oldLoc.longitude}',
      'newValue': '${newLoc.latitude},${newLoc.longitude}',
    });
  }

  @override
  void dispose() {
    _eventStreamSub.cancel();
    super.dispose();
  }
}
