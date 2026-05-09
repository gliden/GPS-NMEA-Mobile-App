// lib/services/background_service.dart
//
// Kapselt flutter_background_service.
// Der Hintergrundprozess läuft als isolierter Dart-Isolate und kommuniziert
// per SendPort/ReceivePort-ähnlichen Nachrichten mit dem UI.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gps_nmea_tracker/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nmea_builder.dart';
import 'http_transmitter.dart';

// ── Öffentliche Initialisierung ───────────────────────────────────────────

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Notification channel (Android 8+)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'gps_nmea_channel',
    'GPS NMEA Tracker',
    description: 'GPS-Tracking läuft im Hintergrund',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onBackgroundServiceStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'gps_nmea_channel',
      initialNotificationTitle: 'GPS NMEA Tracker',
      initialNotificationContent: 'Initialisierung…',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onBackgroundServiceStart,
      onBackground: onIosBackground,
    ),
  );
}

// iOS-Background-Handler (muss top-level sein)
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// ── Hintergrund-Einstiegspunkt ────────────────────────────────────────────

@pragma('vm:entry-point')
void onBackgroundServiceStart(ServiceInstance service) async {
  // DartPluginRegistrant.ensureInitialized();

  // Notification-Update-Referenz für Android
  final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

  // Einstellungen laden
  String endpointUrl = await SettingsService().getEndpointUrl();
  int intervalSeconds = await SettingsService().getIntervalSeconds();

  // Auf Konfigurationsänderungen vom UI reagieren
  service.on('update_config').listen((data) {
    if (data == null) return;
    if (data['endpoint_url'] != null) endpointUrl = data['endpoint_url'];
    if (data['interval_seconds'] != null) intervalSeconds = data['interval_seconds'];
  });

  service.on('stop').listen((_) {
    service.stopSelf();
  });

  // Periodischer GPS-Task
  Timer.periodic(Duration(seconds: intervalSeconds), (_) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final sentence = NmeaBuilder.build(
        latitudeDeg: position.latitude,
        longitudeDeg: position.longitude,
        speedMs: position.speed,
        headingDeg: position.heading,
        utc: DateTime.now().toUtc(),
      );

      // An UI senden
      service.invoke('nmea_sentence', {
        'raw': sentence.rawSentence,
        'lat': sentence.latitude,
        'lon': sentence.longitude,
        'speed': sentence.speedKnots,
        'course': sentence.courseDegrees,
        'timestamp': sentence.timestamp.toIso8601String(),
        'status': 'sending',
      });

      // HTTP-Übertragung
      final transmitter = HttpTransmitter(endpointUrl: endpointUrl);
      await transmitter.send(sentence);

      service.invoke('nmea_sentence', {
        'raw': sentence.rawSentence,
        'lat': sentence.latitude,
        'lon': sentence.longitude,
        'speed': sentence.speedKnots,
        'course': sentence.courseDegrees,
        'timestamp': sentence.timestamp.toIso8601String(),
        'status': 'success',
      });

      // Notification aktualisieren
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'GPS NMEA Tracker',
          content: '${sentence.latitude.toStringAsFixed(5)}, ${sentence.longitude.toStringAsFixed(5)}',
        );
      }
    } catch (e) {
      service.invoke('nmea_sentence', {
        'raw': '',
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    }
  });
}

// ── Steuerung vom UI aus ──────────────────────────────────────────────────

class BackgroundServiceController {
  final FlutterBackgroundService _service = FlutterBackgroundService();

  Future<bool> isRunning() => _service.isRunning();

  Future<void> start() async {
    await _service.startService();
  }

  Future<void> stop() async {
    _service.invoke('stop');
  }

  Future<void> updateConfig({
    required String endpointUrl,
    required int intervalSeconds,
  }) async {
    _service.invoke('update_config', {
      'endpoint_url': endpointUrl,
      'interval_seconds': intervalSeconds,
    });
  }

  /// Stream eingehender NMEA-Nachrichten aus dem Hintergrundprozess
  Stream<Map<String, dynamic>?> get nmeaStream => _service.on('nmea_sentence');
}
