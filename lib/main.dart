// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/background_service.dart';
import 'viewmodels/tracker_viewmodel.dart';
import 'views/tracker_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hintergrundienst registrieren (keine Autostart, nur vorbereiten)
  await initializeBackgroundService();

  runApp(
    ChangeNotifierProvider(
      create: (_) => TrackerViewModel()..init(),
      child: const GpsNmeaApp(),
    ),
  );
}

class GpsNmeaApp extends StatelessWidget {
  const GpsNmeaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS NMEA Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0057FF),
        brightness: Brightness.light,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(elevation: 0, scrolledUnderElevation: 1),
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF0057FF),
        brightness: Brightness.dark,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(elevation: 0, scrolledUnderElevation: 1),
      ),
      home: const TrackerScreen(),
    );
  }
}
