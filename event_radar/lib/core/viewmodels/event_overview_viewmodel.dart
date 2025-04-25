import 'package:flutter/foundation.dart';
import '../models/participant.dart';
import '../services/participant_service.dart';

class EventOverviewViewModel extends ChangeNotifier {
  final String eventId;
  List<ParticipantProfile> participants = [];
  bool isLoading = false;
  String? error;

  EventOverviewViewModel(this.eventId) {
    _loadParticipants();
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
}
