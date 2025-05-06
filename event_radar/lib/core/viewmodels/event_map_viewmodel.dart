import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/event_service.dart';

class EventMapViewModel extends ChangeNotifier {
  final EventService _eventService = EventService();

  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<Event>>? _publicSub;
  StreamSubscription<List<Event>>? _userSub;

  List<Event> _publicEvents = [];
  List<Event> _userEvents = [];

  List<Event> events = [];
  bool isLoading = false;

  EventMapViewModel() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  void _onAuthChanged(User? user) {
    _publicSub?.cancel();
    _userSub?.cancel();

    isLoading = true;
    notifyListeners();

    _publicSub = _eventService.getPublicEventsStream().listen((pubEvents) {
      _publicEvents = pubEvents;
      _mergeEvents();
    });

    if (user != null) {
      _userSub = _eventService.getUserEventsStream(user.uid).listen((
        usrEvents,
      ) {
        _userEvents = usrEvents;
        _mergeEvents();
      });
    } else {
      _userEvents = [];
      _mergeEvents();
    }
  }

  void _mergeEvents() {
    final map = <String, Event>{};
    for (var e in _publicEvents) {
      map[e.id!] = e;
    }
    for (var e in _userEvents) {
      map[e.id!] = e;
    }
    events = map.values.toList();
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _publicSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
