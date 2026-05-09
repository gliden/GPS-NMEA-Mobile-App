// lib/views/privacy_policy_screen.dart
//
// Datenschutzrichtlinie für die App.

import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datenschutzrichtlinie')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            'Datenschutzrichtlinie für GPS NMEA Tracker\n\n'
            'Diese App sammelt GPS-Positionsdaten in Echtzeit und formatiert sie in das NMEA-0183 GPRMC-Format. '
            'Die Daten werden per HTTP-POST an einen vom Benutzer konfigurierbaren Server gesendet.\n\n'
            'Gesammelte Daten:\n'
            '- Breitengrad, Längengrad, Geschwindigkeit, Kurs und Zeitstempel.\n'
            '- Die Daten werden nur für das Tracking verwendet und nicht dauerhaft gespeichert oder an Dritte weitergegeben.\n\n'
            'Berechtigungen:\n'
            '- Standortberechtigung: Erforderlich für GPS-Zugriff im Vordergrund und Hintergrund.\n'
            '- Für kontinuierliches Tracking muss "Immer erlauben" in den Android-Einstellungen aktiviert werden.\n\n'
            'Datenspeicherung:\n'
            '- Einstellungen (z. B. Server-URL, Intervall) werden lokal auf dem Gerät gespeichert.\n'
            '- Übertragungsverlauf wird temporär im RAM gehalten (max. 100 Einträge).\n\n'
            'Weitergabe:\n'
            '- Daten werden nur an den konfigurierten Server gesendet. Der Benutzer ist für die Sicherheit des Servers verantwortlich.\n\n'
            'Rechte:\n'
            '- Du kannst die App jederzeit deinstallieren, um die Datensammlung zu stoppen.\n'
            '- Für Fragen: [Deine Kontaktinformationen hier einfügen].\n\n'
            'Letzte Aktualisierung: Mai 2026.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
