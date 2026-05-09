// lib/services/settings_service.dart
//
// Persistiert Benutzereinstellungen (Endpunkt-URL, Sendeintervall).

import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyUrl = 'endpoint_url';
  static const _keyInterval = 'interval_seconds';

  static const String defaultUrl = 'http://192.168.178.60/gps/collect.php';
  static const int defaultInterval = 5;

  Future<String> getEndpointUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUrl) ?? defaultUrl;
  }

  Future<void> setEndpointUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUrl, url);
  }

  Future<int> getIntervalSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyInterval) ?? defaultInterval;
  }

  Future<void> setIntervalSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyInterval, seconds);
  }
}
