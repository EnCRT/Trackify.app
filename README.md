# MotoLapTimer 🏁🏍️

MotoLapTimer is a Flutter mobile app for motocross / track riders that turns raw GPS tracks into **laps + sectors** you can actually analyze.

What you can do (today):
- 📥 Import GPS tracks (`.gpx` / `.txt`(not now))
- 🗺️ Mark **Start/Finish** and sector gates
- ⏱️ Auto-calculate laps + sector times from GPS data
- 🎨 Speed heatmap (speed → track color)
- 📊 Session details: map, stats, lap selector, sector analysis table (absolute + delta mode)
- 🧰 Garage + user profile (local, offline-friendly)

---

## Technical 🛠️

### Stack
- **Language**: Dart 3.11+
- **Framework/UI**: Flutter (Material 3)
- **State**: Provider (`ChangeNotifier`)
- **Database**: SQLite (`sqflite`)
- **Maps**: `flutter_map` + OpenStreetMap tiles
- **GPS utilities**: `latlong2`
- **GPX parsing**: `xml`
- **File picking**: `file_picker`
- **Localization**: Flutter `intl` + ARB (`ru`, `uk`, `en`)

### Project structure (high level)
```text
lib/
  models/      data entities (User, Vehicle, Session, Lap…)
  providers/   app state (ChangeNotifier)
  services/    parsing + lap/sector calculation + DB helper
  screens/     UI screens
  l10n/        ARB + generated localization files
```

### Dev commands (PowerShell) ⚙️
```powershell
# Install dependencies
flutter pub get

# Run in debug (hot reload: r, hot restart: R)
flutter run

# Build APK (release)
flutter build apk --release

# Build App Bundle (Google Play)
flutter build appbundle

# Clean build artifacts
flutter clean

# Diagnostics
flutter doctor
```

### Notes 🧩
- **TXT import format**: `lat,lng,timestamp_millis`
- **Local-first**: sessions, bikes, profile are stored in SQLite.
