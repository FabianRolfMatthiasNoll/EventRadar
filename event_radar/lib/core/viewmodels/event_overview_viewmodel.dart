import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/event.dart';
import '../models/participant.dart';
import '../services/event_service.dart';
import '../services/participant_service.dart';

class EventOverviewViewModel extends ChangeNotifier {
  final String eventId;
  final EventService _eventService = EventService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Event? event;
  bool isEventLoading = true;
  String? eventError;

  bool? isOrganizer;
  bool isCheckingOrganizer = false;
  String? organizerError;

  List<ParticipantProfile> participants = [];
  bool isParticipantsLoading = false;
  String? participantsError;

  late final StreamSubscription<Event> _eventSub;

  EventOverviewViewModel(this.eventId) {
    _init();
  }

  void _init() {
    _subscribeEvent();
    _checkOrganizer();
    _loadParticipants();
  }

  void _subscribeEvent() {
    _eventSub = _eventService
        .getEventStream(eventId)
        .listen(_onEventData, onError: _onEventError);
  }

  void _onEventData(Event evt) {
    event = evt;
    isEventLoading = false;
    notifyListeners();
    _loadParticipants();
  }

  void _onEventError(Object e) {
    eventError = e.toString();
    isEventLoading = false;
    notifyListeners();
  }

  Future<void> _checkOrganizer() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      isOrganizer = false;
      return;
    }
    isCheckingOrganizer = true;
    notifyListeners();
    try {
      final doc =
          await _firestore
              .collection('events')
              .doc(eventId)
              .collection('participants')
              .doc(uid)
              .get();
      final role = doc.data()?['role'] as String?;
      isOrganizer = (role == 'organizer');
    } catch (e) {
      organizerError = e.toString();
      isOrganizer = false;
    } finally {
      isCheckingOrganizer = false;
      notifyListeners();
    }
  }

  Future<void> _loadParticipants() async {
    isParticipantsLoading = true;
    participantsError = null;
    notifyListeners();
    try {
      participants = await ParticipantService.fetch(eventId);
    } catch (e) {
      participants = [];
      participantsError = e.toString();
    } finally {
      isParticipantsLoading = false;
      notifyListeners();
    }
  }

  // Alle Update-Methoden unverändert:
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

  Future<void> clearEndDate(DateTime? oldEnd) async {
    await _eventService.updateEvent(eventId, {'endDate': FieldValue.delete()});
    await _eventService.logEventChange(eventId, {
      'type': 'end_date_change',
      'oldValue': oldEnd?.toIso8601String(),
      'newValue': null,
    });
  }

  Future<void> updateImage(String newUrl, String oldUrl) async {
    await _eventService.updateEvent(eventId, {'image': newUrl});
    await _eventService.logEventChange(eventId, {
      'type': 'image_change',
      'oldValue': oldUrl,
      'newValue': newUrl,
    });
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

  Future<void> promoteToOrganizer(String userId) async {
    await EventService().changeParticipantRole(eventId, userId, 'organizer');
    await _loadParticipants();
  }

  Future<void> demoteFromOrganizer(String userId) async {
    await EventService().changeParticipantRole(eventId, userId, 'participant');
    await _loadParticipants();
  }

  Future<void> kickParticipant(String userId) async {
    await EventService().leaveEvent(eventId, userId);
    await _loadParticipants();
  }

  @override
  void dispose() {
    _eventSub.cancel();
    super.dispose();
  }
}
