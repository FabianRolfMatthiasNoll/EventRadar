import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String _newEmailSuffix = '_new_email';

  static String _getKey(String userId, String suffix) => '$userId$suffix';

  // Speichern der neuen E-Mail
  static Future<void> saveNewEmail(String userId, String newEmail) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getKey(userId, _newEmailSuffix), newEmail);
  }

  // Abrufen der neuen E-Mail
  static Future<String?> getNewEmail(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_getKey(userId, _newEmailSuffix));
  }

  // Löschen der neuen E-Mail
  static Future<void> clearNewEmail(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getKey(userId, _newEmailSuffix));
  }
}
