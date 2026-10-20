# LPU Maps Pro - Smart Campus Navigator 🗺️🎓

An interactive, high-performance campus navigation and block finder application built with Flutter, designed specifically for **Lovely Professional University (LPU)** spanning over 600+ acres.

---

## 🌟 Key Features

- **🧭 Turn-by-Turn Campus Navigation:**
  - Shortest walking route calculations via OpenStreetMap / OSRM routing.
  - Real-time turn-by-turn directions HUD with visual maneuver icons.
  - Automatic off-route detection (>35m) with automatic shortcut recalculation.
  - Real-time step announcement via Indian-English voice guidance (`flutter_tts`).

- **📍 Campus Points of Interest (POIs):**
  - Academic blocks (Blocks 14 through 57, Mittal School of Business, Aerospace, Polytechnic).
  - Central Library (9-storey resource center with 24-hr status).
  - Residential zones (Boys & Girls Hostels, Uni Mall, Food Factory, Uni Polis).
  - Health & Emergency (Uni Health Care, 24x7 Ambulance).
  - Synced dynamically with Supabase cloud database.

- **🚨 1-Tap Campus Emergency SOS:**
  - Direct quick-dial to Uni Health Care Hospital & Ambulance (`01824-517100`).
  - Campus Security Control Room (`01824-517000`).
  - Proctorial Cell & Women Safety Helpline (`1091`).

- **🎨 Multi-Style Map Layers & Dark Mode:**
  - OpenStreetMap Standard Cartography.
  - Voyager Clean Vector Light Mode.
  - Night-friendly Dark Mode Navigator.
  - Full Material 3 dynamic theming with LPU Orange (`#F58220`) brand identity.

- **❤️ Saved Places & Recent Searches:**
  - Bookmark frequent classrooms, labs, mess, and hostels with local persistence.
  - Fast search suggestions with category tags and real-time distance calculation.

- **📡 Offline Mode & Compass Heading:**
  - Automatic offline detection with fallback routing.
  - Real-time digital compass orientation (`flutter_compass`).
  - Tap-to-reorient North button.

---

## 🏗️ Architecture & Project Structure

The project has been refactored into a scalable, maintainable modular structure:

```
lib/
├── constants/
│   ├── app_colors.dart         # LPU brand colors, category tints, and dark mode palette
│   ├── app_constants.dart      # Campus bounds, tile servers, Supabase keys
│   └── campus_data.dart        # Comprehensive catalog of 35+ default campus locations
├── models/
│   ├── emergency_contact.dart  # Emergency contacts with phone launch metadata
│   ├── navigation_step.dart    # Maneuver icons, distances, and voice instructions
│   └── place.dart              # POI model with distance calculation & JSON serialization
├── services/
│   ├── location_service.dart   # Geolocator stream & permissions handling
│   ├── preferences_service.dart# SharedPreferences for favorites, recents, theme & voice
│   ├── routing_service.dart    # OSRM walking path engine & offline fallback
│   ├── supabase_service.dart   # Supabase cloud authentication & dynamic POIs
│   └── tts_service.dart        # Voice announcement engine with mute toggle
├── theme/
│   └── app_theme.dart          # Light and Dark Material 3 theme configurations
├── widgets/
│   ├── auth/                   # Supabase login & sign-up modal
│   ├── common/                 # Campus drawer with stats, developer credits & settings
│   ├── emergency/              # Emergency SOS dialog with direct dialers
│   ├── map/                    # CampusMapView, MapControls, TurnByTurnHud
│   ├── places/                 # CategoryFilterBar, PlaceDetailsSheet, PlacesBottomSheet
│   └── search/                 # CampusSearchBar & SearchSuggestionsOverlay
├── screens/
│   ├── splash_screen.dart      # Animated onboarding with campus permissions check
│   └── map_screen.dart         # Unified map navigation control center
└── main.dart                   # Application entry point
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>= 3.13.0)
- Android SDK (API 34+) or physical Android/iOS test device
- GPS / Location services enabled

### Run Locally
```bash
# Fetch upgraded dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run unit and widget tests
flutter test

# Run app on connected device or emulator
flutter run
```

### Build APK
```bash
flutter build apk --release
```
