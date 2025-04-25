import 'package:cloud_functions/cloud_functions.dart';

import '../models/participant.dart';

class ParticipantService {
  static Future<List<ParticipantProfile>> fetch(String eventId) async {
    final callable =
    FirebaseFunctions.instance.httpsCallable('getEventParticipants');
    final result = await callable.call({'eventId': eventId});
    final data = (result.data as Map)['participants'] as List<dynamic>;
    return data.map((p) => ParticipantProfile.fromMap(p)).toList();
  }
}