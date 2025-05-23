import 'package:flutter/foundation.dart';

/// Hält den aktuell geöffneten Announcement-Channel im Auge.
class NotificationProvider extends ChangeNotifier {
  String? currentEventId;
  String? currentChannelId;

  /// Rufe auf, wenn man einen Announcement-Channel öffnet oder verlässt.
  void setActiveAnnouncement(String? eventId, String? channelId) {
    currentEventId = eventId;
    currentChannelId = channelId;
    notifyListeners();
  }
}
