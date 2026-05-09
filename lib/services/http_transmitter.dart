// lib/services/http_transmitter.dart
//
// Sendet eine GPRMC-Sentence als HTTP-POST an einen konfigurierbaren Endpunkt.
// Content-Type: text/plain  (rohe NMEA-Zeile im Body)

import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/nmea_sentence.dart';

class HttpTransmitter {
  final String endpointUrl;
  final Duration timeout;

  const HttpTransmitter({
    required this.endpointUrl,
    this.timeout = const Duration(seconds: 10),
  });

  /// Sendet [sentence] per POST. Wirft eine Exception bei Fehler.
  Future<void> send(GprmcSentence sentence) async {
    final uri = Uri.parse(endpointUrl);

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
