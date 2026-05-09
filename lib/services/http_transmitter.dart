// lib/services/http_transmitter.dart
//
// Sendet eine GPRMC-Sentence als HTTP-POST an einen konfigurierbaren Endpunkt.
// Content-Type: text/plain  (rohe NMEA-Zeile im Body)
// Query-Parameter: imei (Gerätename), serial_num (Seriennummer)

import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/nmea_sentence.dart';

class HttpTransmitter {
  final String endpointUrl;
  final String deviceName;
  final String serialNumber;
  final Duration timeout;

  const HttpTransmitter({
    required this.endpointUrl,
    required this.deviceName,
    required this.serialNumber,
    this.timeout = const Duration(seconds: 10),
  });

  /// Sendet [sentence] per POST mit Query-Parametern. Wirft eine Exception bei Fehler.
  Future<void> send(GprmcSentence sentence) async {
    final uri = Uri.parse(endpointUrl).replace(
      queryParameters: {
        'imei': deviceName,
        'serial_num': serialNumber,
      },
    );

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'text/plain; charset=utf-8',
            'User-Agent': 'GpsNmeaTracker/1.0',
          },
          body: sentence.rawSentence,
        )
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpTransmissionException(
        'Server antwortete mit ${response.statusCode}: ${response.body}',
        response.statusCode,
      );
    }
  }
}

class HttpTransmissionException implements Exception {
  final String message;
  final int statusCode;
  const HttpTransmissionException(this.message, this.statusCode);

  @override
  String toString() => 'HttpTransmissionException($statusCode): $message';
}
