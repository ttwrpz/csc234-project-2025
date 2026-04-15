# MoodBloom

A cross-platform Flutter mood tracking app where users log their emotions and watch a virtual garden grow. Positive moods (happy, calm, grateful) grow flowers and plants; negative moods (angry, sad, anxious) spawn bugs that fade away over time.

Built for **CSC231** (Agile Software Engineering) and **CSC234** (User-Centric Mobile App Development) at School of Information Technology, KMUTT.

---

## Features

- **Mood Logging** - Select from 10 emotions with text notes and photo/video attachments
- **Virtual Garden** - Visual garden that grows based on your mood entries (last 30 days)
- **History & Calendar** - Browse past entries in list or calendar view with mood filters
- **Streak Tracking** - Track consecutive days of mood logging
- **Offline Support** - SQLite cache on Android, syncs to Firestore when online
- **Authentication** - Email/password and Google Sign-In via Firebase
- **Cross-Platform** - Runs on Android and Web

---

## Screens

| Screen | Description |
|--------|-------------|
| Onboarding | 3-page intro carousel (shown once) |
| Login/Register | Email + Google auth with validation |
| Home (Garden) | Garden view, greeting, streak, weekly summary |
| Log Mood | Mood selector, text input, photo/video attachment |
| History | List + calendar views with mood filters |
| Entry Detail | Full entry view with edit/delete |
| Settings | Profile, animation speed, notifications, logout, delete account |

---

## Prerequisites

- **Flutter SDK** (3.10+): https://docs.flutter.dev/get-started/install
- **Android SDK** (via Android Studio)
- **Firebase project** (already configured via `flutterfire configure`)

Verify setup:
```bash
flutter doctor
```

---

## Setup & Run

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Run on Android
```bash
flutter run
```

### 3. Run on Web
```bash
flutter run -d chrome
```

### Firebase Setup (if cloning fresh)
Firebase is pre-configured. If you need to reconfigure:
```bash
flutterfire configure
```
Ensure Email/Password and Google Sign-In are enabled in the Firebase Console under Authentication > Sign-in method.

---

## Architecture

```
lib/
├── main.dart                 # Entry point, provider setup
├── app.dart                  # MaterialApp, routes, startup logic
├── config/
│   ├── theme.dart            # Color palette, typography, component themes
│   ├── routes.dart           # Named route constants
│   └── constants.dart        # App-wide constants
├── models/
│   ├── mood_type.dart        # MoodType enum (10 moods with properties)
│   ├── mood_entry.dart       # MoodEntry model (Firestore + SQLite serialization)
│   └── user_profile.dart     # UserProfile model
├── services/
│   ├── auth_service.dart     # Firebase Auth (email, Google, password reset)
│   ├── firestore_service.dart# Firestore CRUD for moods and users
│   ├── storage_service.dart  # Firebase Storage for attachments
│   ├── local_db_service.dart # SQLite (Android) / in-memory (Web) abstraction
│   └── preferences_service.dart # SharedPreferences wrapper
├── providers/
│   ├── auth_provider.dart    # Auth state + user profile
│   ├── mood_provider.dart    # Mood entries, save/edit/delete, streak
│   ├── garden_provider.dart  # Garden elements from mood data
│   └── settings_provider.dart# Animation speed, notifications, dark mode
├── screens/                  # All app screens
├── widgets/                  # Reusable widgets (MoodChip, MoodCard, etc.)
└── utils/
    ├── date_helpers.dart     # Date formatting, streak calculation
    ├── validators.dart       # Email/password validation
    └── sync_manager.dart     # Offline sync logic
```

**State Management:** Provider (ChangeNotifier pattern)

**Data Flow:**
1. User actions trigger Provider methods
2. Providers call Services (Firebase, SQLite, SharedPreferences)
3. UI rebuilds via `context.watch<Provider>()`

**Offline Strategy:**
- Mood entries save to local SQLite first, then sync to Firestore
- Unsynced entries push to Firestore when connectivity is restored
- Settings stored in SharedPreferences (no cloud sync)

---

## Testing

### Run all unit and widget tests
```bash
flutter test
```

### Test files
| Test | What it covers |
|------|---------------|
| `test/models/mood_entry_test.dart` | Model serialization (Firestore + SQLite roundtrip) |
| `test/models/mood_type_test.dart` | Enum values, categories, fromString |
| `test/utils/validators_test.dart` | Email, password, display name validation |
| `test/utils/date_helpers_test.dart` | Date formatting, streak calculation, week days |
| `test/widgets/mood_chip_test.dart` | Render, selection state, tap callback |
| `test/widgets/mood_card_test.dart` | Mood display, text preview, attachment icons |
| `test/widgets/confirmation_dialog_test.dart` | Title/message display, confirm/cancel returns |

### Integration tests (requires device/emulator)
```bash
# Android
flutter test integration_test/

# Web
flutter test integration_test/ -d chrome
```

---

## Design System

| Token | Color | Hex |
|-------|-------|-----|
| Primary | Forest Green | `#4A7C59` |
| Primary Light | Sage Green | `#6B9F7A` |
| Secondary | Dusty Rose | `#C27A8A` |
| Accent | Warm Gold | `#E8B954` |
| Background | Warm Off-White | `#FAF8F5` |
| Card | Light Cream | `#F5F0EB` |

**Typography:** Nunito (headings), Inter (body) via Google Fonts

---

## Known Limitations

- Garden view uses emoji-based elements (MVP) — art assets planned for later sprints
- Video recording from camera not supported on Web (gallery pick only)
- Push notifications setting persists but actual notification delivery is not implemented
- Dark mode toggle exists in settings but dark theme is not yet implemented
- Integration tests require a running Firebase emulator or test project

---

## Useful Commands

```bash
flutter doctor          # Check environment
flutter pub get         # Install dependencies
flutter analyze         # Static analysis
flutter test            # Run tests
flutter run             # Run on connected device
flutter run -d chrome   # Run on web
flutter clean           # Clean build artifacts
```
