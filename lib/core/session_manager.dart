import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyToken = 'partner_auth_token';
  static const String _keyPartnerData = 'partner_profile_data';

  /// Saves the Sanctum session token and partner details persistently
  static Future<void> saveSession({
    required String token,
    required Map<String, dynamic> partnerData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyPartnerData, jsonEncode(partnerData));
  }

  /// Updates the saved partner details persistently
  static Future<void> updatePartnerData(Map<String, dynamic> partnerData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPartnerData, jsonEncode(partnerData));
  }

  /// Retrieves the saved authentication token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Retrieves the saved partner profile details
  static Future<Map<String, dynamic>?> getPartnerData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_keyPartnerData);
    if (dataString != null) {
      try {
        return jsonDecode(dataString) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Checks if an active session exists on the device
  static Future<bool> hasSession() async {
    final token = await getToken();
    final partner = await getPartnerData();
    return token != null && partner != null;
  }

  /// Clears the persistent session data (logs the user out)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyPartnerData);
  }
}
