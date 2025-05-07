import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String _oldEmailSuffix = '_old_email';
  static const String _newEmailSuffix = '_new_email';
  static const String _emailPendingSuffix = '_email_pending';

  static String _getKey(String userId, String suffix) => '$userId$suffix';

  static Future<void> saveOldEmail({
    required String userId,
    required String oldEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getKey(userId, _oldEmailSuffix), oldEmail);
  }

  static Future<String?> getOldEmail(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_getKey(userId, _oldEmailSuffix));
  }

  static Future<void> clearOldEmail(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getKey(userId, _oldEmailSuffix));
  }

  static Future<void> saveNewEmail({
    required String userId,
    required String newEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getKey(userId, _newEmailSuffix), newEmail);
  }

  static Future<String?> getNewEmail(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_getKey(userId, _newEmailSuffix));
  }

  static Future<void> clearNewEmail(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getKey(userId, _newEmailSuffix));
  }

  static Future<void> setEmailPending(String userId, bool isPending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_getKey(userId, _emailPendingSuffix), isPending);
  }

  static Future<bool> isEmailPending(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_getKey(userId, _emailPendingSuffix)) ?? false;
  }

  static Future<void> clearEmailPending(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getKey(userId, _emailPendingSuffix));
  }
}
