# GPS NMEA Tracker – Flutter App

Überträgt GPS-Positionsdaten im NMEA-0183-Format (ausschließlich `$GPRMC`) per HTTP-POST an einen konfigurierbaren Webservice. Unterstützt Hintergrundbetrieb auf **iOS** und **Android**.

---

## Architektur

```
lib/
├── main.dart                          ← App-Einstiegspunkt, Provider-Setup
│
├── models/
│   └── nmea_sentence.dart             ← Reine Datenklassen (GprmcSentence, TransmissionResult)
│
├── services/
│   ├── nmea_builder.dart              ← GPS → GPRMC-String (kein Flutter, voll testbar)
│   ├── http_transmitter.dart          ← HTTP-POST-Übertragung
│   ├── background_service.dart        ← flutter_background_service Wrapper + Isolate-Einstiegspunkt
│   ├── location_permission_service.dart ← Berechtigungsabfragen
│   └── settings_service.dart          ← SharedPreferences-Persistierung
│
├── viewmodels/
│   └── tracker_viewmodel.dart         ← ChangeNotifier, verbindet Services mit UI
│
├── views/
│   ├── tracker_screen.dart            ← Hauptbildschirm
│   └── settings_screen.dart           ← Einstellungen (URL, Intervall)
│
└── widgets/
    ├── status_card.dart               ← Aktueller GPS/Übertragungs-Status
    └── history_list.dart              ← Verlauf der letzten 100 Übertragungen
```

### Schichtenmodell

```
┌────────────────────────────────────────┐
│  Views (tracker_screen, settings)      │  nur Widget-Code, kein Business-Logic
├────────────────────────────────────────┤
│  Widgets (status_card, history_list)   │  reine Darstellungskomponenten
├────────────────────────────────────────┤
│  ViewModel (TrackerViewModel)          │  ChangeNotifier, orchestriert Services
├────────────────────────────────────────┤
│  Services                              │  je eine Verantwortung pro Klasse
│  ├─ NmeaBuilder   (Logik)             │
│  ├─ HttpTransmitter (Netz)            │
│  ├─ BackgroundService (Isolate)       │
│  ├─ LocationPermissionService         │
│  └─ SettingsService (Persistenz)      │
├────────────────────────────────────────┤
│  Models (GprmcSentence, …)            │  unveränderliche Datenklassen
└────────────────────────────────────────┘
```

---

## Hintergrundmodus

| Plattform | Mechanismus |
|-----------|-------------|
| Android   | Foreground Service mit `foregroundServiceType="location"`, persistente Benachrichtigung |
| iOS       | `UIBackgroundModes: location, fetch, processing`; flutter_background_service nutzt BGTaskScheduler |

---

## Setup

### 1. Abhängigkeiten installieren

```bash
flutter pub get
```

### 2. Android – keine weiteren Schritte nötig

Die `AndroidManifest.xml` enthält alle nötigen Berechtigungen und den Service-Eintrag.

**Wichtig:** Ab Android 10 muss der Nutzer in den Systemeinstellungen „**Immer erlauben**" für den Standort wählen. Die App leitet bei Bedarf automatisch in die Einstellungen weiter.

### 3. iOS – Signing konfigurieren

```bash
cd ios && pod install
```

Öffne `ios/Runner.xcworkspace` in Xcode:
- **Signing & Capabilities** → Team auswählen
- **Background Modes** Capability hinzufügen (falls noch nicht via Info.plist aktiv):
  - ☑ Location updates
  - ☑ Background fetch
  - ☑ Background processing

### 4. HTTP-Endpunkt konfigurieren

In der App unter **Einstellungen** (Schraubenschlüssel-Icon):

| Parameter | Beschreibung |
|-----------|-------------|
| URL | Vollständige HTTP-POST-URL, z. B. `http://192.168.1.100:8080/gps` |
| Intervall | Sendeintervall in Sekunden (1–60) |

---

## GPRMC-Format

Gesendetes Format im HTTP-Body (`Content-Type: text/plain`):

```
$GPRMC,123519.00,A,5314.3200,N,00810.5800,E,0.12,45.60,091225,,*XX
```

| Feld | Bedeutung |
|------|-----------|
| `123519.00` | UTC-Zeit (HHMMSS.ss) |
| `A` | Status: A = Active (gültig) |
| `5314.3200,N` | Breitengrad (DDMM.MMMM, N/S) |
| `00810.5800,E` | Längengrad (DDDMM.MMMM, E/W) |
| `0.12` | Geschwindigkeit in Knoten |
| `45.60` | Kurs in Grad |
| `091225` | UTC-Datum (DDMMYY) |
| `*XX` | XOR-Prüfsumme |

---

## Abhängigkeiten

| Paket | Zweck |
|-------|-------|
| `geolocator` | GPS-Zugriff (Vordergrund + Hintergrund) |
| `flutter_background_service` | Dart-Isolate als Foreground Service / iOS Background |
| `flutter_local_notifications` | Android-Benachrichtigung für Foreground Service |
| `http` | HTTP-POST |
| `provider` | Zustandsverwaltung (ChangeNotifier) |
| `shared_preferences` | Persistente Einstellungen |
| `permission_handler` | Berechtigungsabfragen |

---

## Entwicklung & Tests

```bash
# Unit-Tests (NmeaBuilder ist Flutter-unabhängig, vollständig testbar)
flutter test

# App starten
flutter run
```

### Testserver (Python, Einzeiler)

```bash
python3 -c "
from http.server import HTTPServer, BaseHTTPRequestHandler
class H(BaseHTTPRequestHandler):
    def do_POST(self):
        n = int(self.headers.get('Content-Length', 0))
        print(self.rfile.read(n).decode())
        self.send_response(200); self.end_headers()
HTTPServer(('', 8080), H).serve_forever()
"
```
