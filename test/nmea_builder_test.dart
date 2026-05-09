// test/nmea_builder_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:gps_nmea_tracker/services/nmea_builder.dart';

void main() {
  group('NmeaBuilder', () {
    final testTime = DateTime.utc(2025, 12, 9, 12, 35, 19, 500);

    test('erzeugt eine Sentence die mit \$GPRMC beginnt', () {
      final s = NmeaBuilder.build(
        latitudeDeg: 53.239,
        longitudeDeg: 8.1763,
        speedMs: 0.0,
        headingDeg: 0.0,
        utc: testTime,
      );
      expect(s.rawSentence, startsWith(r'$GPRMC'));
    });

    test('Prüfsumme ist korrekt formatiert (2 Hex-Zeichen nach *)', () {
      final s = NmeaBuilder.build(
        latitudeDeg: 53.239,
        longitudeDeg: 8.1763,
        speedMs: 0.0,
        headingDeg: 0.0,
        utc: testTime,
      );
      final parts = s.rawSentence.split('*');
      expect(parts.length, 2);
      expect(parts[1].length, 2);
      expect(RegExp(r'^[0-9A-F]{2}$').hasMatch(parts[1]), isTrue);
    });

    test('XOR-Prüfsumme stimmt', () {
      final s = NmeaBuilder.build(
        latitudeDeg: 53.239,
        longitudeDeg: 8.1763,
        speedMs: 2.5,
        headingDeg: 180.0,
        utc: testTime,
      );
      // Prüfsumme berechnen
      final inner = s.rawSentence.substring(1, s.rawSentence.indexOf('*'));
      int expected = 0;
      for (final c in inner.codeUnits) {
        expected ^= c;
      }
      final expectedHex =
          expected.toRadixString(16).toUpperCase().padLeft(2, '0');
      expect(s.rawSentence, endsWith('*$expectedHex'));
    });

    test('Nordbreitengrad → N Hemisphäre', () {
      final s = NmeaBuilder.build(
        latitudeDeg: 53.0,
        longitudeDeg: 8.0,
        speedMs: 0.0,
        headingDeg: 0.0,
        utc: testTime,
      );
      expect(s.rawSentence, contains(',N,'));
    });

    test('Ostlängengrad → E Hemisphäre', () {
      final s = NmeaBuilder.build(
        latitudeDeg: 53.0,
        longitudeDeg: 8.0,
        speedMs: 0.0,
        headingDeg: 0.0,
        utc: testTime,
      );
      expect(s.rawSentence, contains(',E,'));
    });

    test('Südbreitengrad → S Hemisphäre', () {
      final s = NmeaBuilder.build(
        latitudeDeg: -33.8688,
        longitudeDeg: 151.2093,
        speedMs: 0.0,
        headingDeg: 0.0,
        utc: testTime,
      );
      expect(s.rawSentence, contains(',S,'));
    });

    test('Geschwindigkeit wird in Knoten umgerechnet', () {
      final s = NmeaBuilder.build(
        latitudeDeg: 0.0,
        longitudeDeg: 0.0,
        speedMs: 1.0, // 1 m/s = 1.94384 kn
        headingDeg: 0.0,
        utc: testTime,
      );
      expect(s.speedKnots, closeTo(1.94384, 0.001));
    });
  });
}
