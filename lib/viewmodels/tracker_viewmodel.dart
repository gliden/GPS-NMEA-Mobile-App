// lib/viewmodels/tracker_viewmodel.dart
//
// Bindeglied zwischen Diensten und UI. Kein Widget-Code hier.

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/nmea_sentence.dart';
import '../services/background_service.dart';
import '../services/location_permission_service.dart';
import '../services/settings_service.dart';

class TrackerViewModel extends ChangeNotifier {
  // ── Abhängigkeiten ────────────────────────────────────────────────────────
  final BackgroundServiceController _bgController;
  final LocationPermissionService _permissionService;
  final SettingsService _settingsService;

  TrackerViewModel({
    BackgroundServiceController? bgController,
    LocationPermissionService? permissionService,
    SettingsService? settingsService,
  })  : _bgController = bgController ?? BackgroundServiceController(),
        _permissionService = permissionService ?? LocationPermissionService(),
        _settingsService = settingsService ?? SettingsService();

  // ── Zustand ───────────────────────────────────────────────────────────────
  bool _isTracking = false;
  bool get isTracking => _isTracking;

  String _endpointUrl = SettingsService.defaultUrl;
  String get endpointUrl => _endpointUrl;

  int _intervalSeconds = SettingsService.defaultInterval;
  int get intervalSeconds => _intervalSeconds;

  String _deviceName = '';
  String get deviceName => _deviceName;

  String _serialNumber = '';
  String get serialNumber => _serialNumber;

  GprmcSentence? _lastSentence;
  GprmcSentence? get lastSentence => _lastSentence;

  TransmissionStatus _transmissionStatus = TransmissionStatus.idle;
  TransmissionStatus get transmissionStatus => _transmissionStatus;

  String? _lastError;
  String? get lastError => _lastError;

  final List<TransmissionResult> _history = [];
  List<TransmissionResult> get history => List.unmodifiable(_history);

  StreamSubscription? _nmeaSubscription;

  // ── Initialisierung ───────────────────────────────────────────────────────
  Future<void> init() async {
    _endpointUrl = await _settingsService.getEndpointUrl();
    _intervalSeconds = await _settingsService.getIntervalSeconds();
    _deviceName = await _settingsService.getDeviceName();
    _serialNumber = await _settingsService.getSerialNumber();
    _isTracking = await _bgController.isRunning();
    if (_isTracking) _subscribeToBackground();
    notifyListeners();
  }

  // ── Steuerung ─────────────────────────────────────────────────────────────
  Future<String?> startTracking() async {
    final state = await _permissionService.requestPermissions();

    if (state == LocationPermissionState.serviceDisabled) {
      return 'GPS-Dienst ist deaktiviert. Bitte aktiviere den Standortdienst.';
    }
    if (state == LocationPermissionState.deniedForever) {
      await _permissionService.openSettings();
      return 'Berechtigung dauerhaft verweigert. Bitte in den Einstellungen freigeben.';
    }
    if (state == LocationPermissionState.deniedOnce) {
      return 'Standortberechtigung wurde verweigert.';
    }

    await _bgController.start();
    await _bgController.updateConfig(
      endpointUrl: _endpointUrl,
      intervalSeconds: _intervalSeconds,
    );

    _isTracking = true;
    _transmissionStatus = TransmissionStatus.idle;
    _subscribeToBackground();
    notifyListeners();
    return null; // Kein Fehler
  }

  Future<void> stopTracking() async {
    await _bgController.stop();
    _isTracking = false;
    _transmissionStatus = TransmissionStatus.idle;
    await _nmeaSubscription?.cancel();
    _nmeaSubscription = null;
    notifyListeners();
  }

  // ── Einstellungen ──────────────────────────────────────────────────────────
  Future<String?> saveSettings({
    required String url,
    required int intervalSeconds,
    required String deviceName,
  }) async {
    // Validierung: Name ist Pflichtfeld
    if (deviceName.trim().isEmpty) {
      return 'Gerätename ist erforderlich.';
    }

    _endpointUrl = url;
    _intervalSeconds = intervalSeconds;
    _deviceName = deviceName.trim();

    await _settingsService.setEndpointUrl(url);
    await _settingsService.setIntervalSeconds(intervalSeconds);
    await _settingsService.setDeviceName(_deviceName);

    if (_isTracking) {
      await _bgController.updateConfig(
        endpointUrl: _endpointUrl,
        intervalSeconds: _intervalSeconds,
      );
    }
    notifyListeners();
    return null; // Kein Fehler
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  // ── Privat ─────────────────────────────────────────────────────────────────
  void _subscribeToBackground() {
    _nmeaSubscription = _bgController.nmeaStream.listen((data) {
      if (data == null) return;

      final statusStr = data['status'] as String? ?? 'idle';
      final status = _parseStatus(statusStr);
      _transmissionStatus = status;

      if (data['raw'] != null && (data['raw'] as String).isNotEmpty) {
        final sentence = GprmcSentence(
          timestamp: DateTime.parse(data['timestamp'] as String),
          latitude: (data['lat'] as num).toDouble(),
          longitude: (data['lon'] as num).toDouble(),
          speedKnots: (data['speed'] as num).toDouble(),
          courseDegrees: (data['course'] as num).toDouble(),
          rawSentence: data['raw'] as String,
        );

        _lastSentence = sentence;
        _lastError = status == TransmissionStatus.error ? data['error'] as String? : null;

        final result = TransmissionResult(
          sentence: sentence,
          status: status,
          errorMessage: _lastError,
          time: DateTime.now(),
        );

        _history.insert(0, result);
        if (_history.length > 100) _history.removeLast();
      } else if (status == TransmissionStatus.error) {
        _lastError = data['error'] as String?;
      }

      notifyListeners();
    });
  }

  TransmissionStatus _parseStatus(String s) {
    switch (s) {
      case 'sending':
        return TransmissionStatus.sending;
      case 'success':
        return TransmissionStatus.success;
      case 'error':
        return TransmissionStatus.error;
      default:
        return TransmissionStatus.idle;
    }
  }

  @override
  void dispose() {
    _nmeaSubscription?.cancel();
    super.dispose();
  }
}
