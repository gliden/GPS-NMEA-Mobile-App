// lib/services/settings_service.dart
//
// Persistiert Benutzereinstellungen (Endpunkt-URL, Sendeintervall, Name, Seriennummer).

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class SettingsService {
  static const _keyUrl = 'endpoint_url';
  static const _keyInterval = 'interval_seconds';
  static const _keyName = 'device_name';
  static const _keySerialNumber = 'serial_number';

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

  Future<String> getDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName) ?? '';
  }

  Future<void> setDeviceName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
  }

  Future<String> getSerialNumber() async {
    final prefs = await SharedPreferences.getInstance();
    var serial = prefs.getString(_keySerialNumber);

    if (serial == null || serial.isEmpty) {
      serial = _generateSerialNumber();
      await prefs.setString(_keySerialNumber, serial);
    }
    return serial;
  }

  /// Generiert eine zufällige Seriennummer im Format SN-XXXXXXXXXX (10 Hex-Zeichen)
  static String _generateSerialNumber() {
    final random = Random();
    const hexChars = '0123456789ABCDEF';
    final buffer = StringBuffer('SN-');
    for (int i = 0; i < 10; i++) {
      buffer.write(hexChars[random.nextInt(hexChars.length)]);
    }
    return buffer.toString();
  }
}
