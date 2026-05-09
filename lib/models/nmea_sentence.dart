// lib/models/nmea_sentence.dart
//
// Reine Datenklasse für eine GPRMC-Sentence sowie den Übertragungsstatus.

class GprmcSentence {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double speedKnots;
  final double courseDegrees;
  final String rawSentence;

  const GprmcSentence({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.speedKnots,
    required this.courseDegrees,
    required this.rawSentence,
  });

  @override
  String toString() => rawSentence;
}

enum TransmissionStatus { idle, sending, success, error }

class TransmissionResult {
  final GprmcSentence sentence;
  final TransmissionStatus status;
  final String? errorMessage;
  final DateTime time;

  const TransmissionResult({
    required this.sentence,
    required this.status,
    this.errorMessage,
    required this.time,
  });
}
