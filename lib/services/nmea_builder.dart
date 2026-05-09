// lib/services/nmea_builder.dart
//
// Wandelt GPS-Rohdaten in eine NMEA-0183-konforme GPRMC-Sentence um.
// Kein Flutter-Bezug – reine Logik, vollständig testbar.

import 'dart:math';
import '../models/nmea_sentence.dart';

class NmeaBuilder {
  /// Erzeugt eine vollständige $GPRMC-Sentence inklusive Prüfsumme.
  static GprmcSentence build({
    required double latitudeDeg,
    required double longitudeDeg,
    required double speedMs,
    required double headingDeg,
    required DateTime utc,
  }) {
    final speedKnots = speedMs * 1.94384;

    final timeStr = _formatTime(utc);
    final dateStr = _formatDate(utc);

    final latStr = _formatLat(latitudeDeg);
    final latHemi = latitudeDeg >= 0 ? 'N' : 'S';
    final lonStr = _formatLon(longitudeDeg);
    final lonHemi = longitudeDeg >= 0 ? 'E' : 'W';

    final speedStr = speedKnots.toStringAsFixed(2);
    final courseStr = headingDeg.toStringAsFixed(2);

    // Felder ohne führendes $ und ohne Prüfsumme
    final body =
        'GPRMC,$timeStr,A,$latStr,$latHemi,$lonStr,$lonHemi,$speedStr,$courseStr,$dateStr,,';

    final checksum = _checksum(body);

    final raw = '\$$body*$checksum';

    return GprmcSentence(
      timestamp: utc,
      latitude: latitudeDeg,
      longitude: longitudeDeg,
      speedKnots: speedKnots,
      courseDegrees: headingDeg,
      rawSentence: raw,
    );
  }

  // ── Hilfsmethoden ────────────────────────────────────────────────────────

  static String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    final cs = (t.millisecond ~/ 10).toString().padLeft(2, '0');
    return '$h$m$s.$cs';
  }

  static String _formatDate(DateTime t) {
    final d = t.day.toString().padLeft(2, '0');
    final mo = t.month.toString().padLeft(2, '0');
    final y = (t.year % 100).toString().padLeft(2, '0');
    return '$d$mo$y';
  }

  /// Dezimalgrad → NMEA ddmm.mmmm
  static String _formatLat(double deg) {
    final abs = deg.abs();
    final degrees = abs.floor();
    final minutes = (abs - degrees) * 60.0;
    return '${degrees.toString().padLeft(2, '0')}${minutes.toStringAsFixed(4).padLeft(7, '0')}';
  }

  /// Dezimalgrad → NMEA dddmm.mmmm
  static String _formatLon(double deg) {
    final abs = deg.abs();
    final degrees = abs.floor();
    final minutes = (abs - degrees) * 60.0;
    return '${degrees.toString().padLeft(3, '0')}${minutes.toStringAsFixed(4).padLeft(7, '0')}';
  }

  /// XOR-Prüfsumme über alle Zeichen zwischen $ und *
  static String _checksum(String body) {
    int cs = 0;
    for (final c in body.codeUnits) {
      cs ^= c;
    }
    return cs.toRadixString(16).toUpperCase().padLeft(2, '0');
  }
}
