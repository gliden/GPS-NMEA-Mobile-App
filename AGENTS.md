# AGENTS.md - GPS NMEA Tracker

## Architecture Overview

This Flutter app implements a GPS NMEA tracker with background operation, using an MVVM pattern with Provider for state management. The app collects GPS data, formats it into NMEA-0183 GPRMC sentences, and transmits them via HTTP POST to a configurable endpoint.

### Core Components
- **Models** (`lib/models/`): Immutable data classes like `GprmcSentence` and `TransmissionResult`
- **Services** (`lib/services/`): Business logic separated by responsibility (e.g., `NmeaBuilder` for pure NMEA formatting, `HttpTransmitter` for network calls)
- **ViewModels** (`lib/viewmodels/`): `TrackerViewModel` orchestrates services and exposes state via `ChangeNotifier`
- **Views** (`lib/views/`): UI screens like `TrackerScreen` and `SettingsScreen`
- **Widgets** (`lib/widgets/`): Reusable UI components like `StatusCard` and `HistoryList`

### Data Flow
1. Background isolate (via `flutter_background_service`) periodically fetches GPS position using `geolocator`
2. `NmeaBuilder` converts position data to GPRMC sentence with checksum
3. `HttpTransmitter` sends raw NMEA string as `text/plain` POST body
4. Results stream back to UI via `BackgroundServiceController.nmeaStream`
5. `TrackerViewModel` updates state and notifies listeners

### Key Design Decisions
- **Isolate-based background**: Uses `flutter_background_service` for true background execution on both platforms
- **Pure services**: Logic classes like `NmeaBuilder` have no Flutter dependencies for testability
- **Stream communication**: UI-background communication via `ServiceInstance.invoke` and `on` listeners
- **Permission handling**: Separate service for location permissions with user guidance to settings
- **Persistence**: Settings stored via `shared_preferences` with defaults (endpoint: `http://192.168.178.60/gps/collect.php`, interval: 5s)

## Development Workflows

### Building and Running
```bash
flutter pub get
flutter run  # Launches on connected device/emulator
```

### Testing
```bash
flutter test  # Runs unit tests (primarily NmeaBuilder)
```

### Platform-Specific Setup
- **Android**: No additional steps; manifest includes location permissions and foreground service config
- **iOS**: 
  ```bash
  cd ios && pod install
  ```
  Open `ios/Runner.xcworkspace` in Xcode, configure signing, and ensure Background Modes capability includes Location updates, Background fetch, and Background processing.

### Debugging Background Service
- Background code runs in a separate Dart isolate; use `print` statements and check device logs
- On Android, foreground service shows persistent notification with current position
- Test HTTP endpoint with the provided Python server script in README.md

## Project Conventions

### Code Organization
- **German comments and UI strings**: All comments and user-facing text are in German
- **Single responsibility services**: Each service handles one concern (e.g., `HttpTransmitter` only does HTTP, `NmeaBuilder` only formats NMEA)
- **No business logic in widgets**: Views and widgets focus on presentation; logic lives in ViewModel/Services
- **Immutable models**: Data classes use `const` constructors and final fields

### NMEA Implementation
- **GPRMC only**: Generates `$GPRMC` sentences with XOR checksum (e.g., `$GPRMC,123519.00,A,5314.3200,N,00810.5800,E,0.12,45.60,091225,,*XX`)
- **Coordinate formatting**: Latitude as DDMM.MMMM, longitude as DDDMM.MMMM
- **Speed conversion**: Meters/second to knots (multiply by 1.94384)
- **Time formatting**: UTC with centiseconds (HHMMSS.ss)

### HTTP Transmission
- **Content-Type**: `text/plain; charset=utf-8`
- **Body**: Raw NMEA sentence string
- **Query-Parameters**: 
  - `imei`: Device name (Gerätename) - configured by user in settings
  - `serial_num`: Unique serial number (Seriennummer) - auto-generated on first app start
- **User-Agent**: `GpsNmeaTracker/1.0`
- **Timeout**: 10 seconds
- **Error handling**: Throws `HttpTransmissionException` on non-2xx responses

### UI Patterns
- **Provider pattern**: `context.watch<TrackerViewModel>()` in widgets
- **History management**: Keeps last 100 `TransmissionResult`s, newest first
- **Long-press actions**: History items copy raw NMEA to clipboard on long press
- **Status indicators**: Color-coded dots and labels for tracking states (idle/sending/success/error)

### Dependencies and Integration
- **GPS**: `geolocator` for position access (requires "Always allow" on Android 10+)
- **Background**: `flutter_background_service` with `flutter_local_notifications` for Android foreground
- **Network**: `http` package for POST requests
- **State**: `provider` for ChangeNotifier-based MVVM
- **Storage**: `shared_preferences` for settings persistence
- **Permissions**: `permission_handler` for initial checks, `geolocator` for location permissions

### Testing Approach
- Focus on pure logic: `NmeaBuilder` is fully unit testable without Flutter
- Use realistic test data (e.g., UTC timestamps, known coordinates)
- Validate checksum calculation and format compliance

### CI/CD with CodeMagic
- **Setup**: Configure your CodeMagic project with Flutter workflow.
- **Signing**: Upload your keystore as a secret in CodeMagic. The build.gradle.kts uses environment variables (CM_KEYSTORE_PATH, CM_KEYSTORE_PASSWORD, CM_KEY_ALIAS, CM_KEY_PASSWORD) for signing.
- **Build Command**: Use `flutter build appbundle --release` in CodeMagic for signed AABs ready for Play Store.
- **iOS**: For iOS builds, ensure provisioning profiles and certificates are set up in CodeMagic.

## Key Files for Reference
- `lib/viewmodels/tracker_viewmodel.dart`: Central state management and service orchestration
- `lib/services/background_service.dart`: Isolate setup and GPS polling loop
- `lib/services/nmea_builder.dart`: NMEA formatting logic with examples
- `lib/main.dart`: Provider setup and app initialization
- `README.md`: Detailed setup and architecture diagrams

### Device Identification
- **Device Name (IMEI)**: Required field in settings. User-configurable and sent as `imei` query parameter in HTTP requests
- **Serial Number**: Auto-generated on first app start (format: `SN-XXXXXXXXXX` with 10 random hex characters), stored persistently, read-only in UI, sent as `serial_num` query parameter
- **Generation Logic**: Serial number is created only once via `SettingsService.getSerialNumber()` on app init and reused across sessions
- **Use Case**: Enables server-side tracking and identification of individual devices without requiring unique hardware identifiers
