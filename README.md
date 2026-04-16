# MoodBloom

A cross-platform Flutter mood tracking app where users log their emotions and watch a virtual garden grow. Positive moods (happy, calm, grateful) grow flowers and plants; negative moods (angry, sad, anxious) spawn bugs that fade away over time.

Built for **CSC231** (Agile Software Engineering) and **CSC234** (User-Centric Mobile App Development) at School of Information Technology, KMUTT.

---

## Features

- **Mood Logging** - Select from 10 emotions with text notes and photo/video attachments
- **Virtual Garden** - Styled plant and bug containers with growth animations and depth-sorted rendering
- **History & Calendar** - Browse past entries in list or calendar view with mood filters and shimmer loading
- **Streak Tracking** - Track consecutive days of mood logging
- **Offline Support** - SQLite cache on Android, syncs to Firestore when online, with connectivity banner
- **Authentication** - Email/password and Google Sign-In via Firebase with user-friendly error messages
- **Cross-Platform** - Runs on Android and Web
- **Dark Mode** - Full dark theme with custom dark color palette
- **Sync Status** - Cloud/local sync indicators on mood cards and settings sync panel
- **Animated Transitions** - Hero animations, fade-through page transitions, success animation overlay

---

## Screens

| Screen | Description |
|--------|-------------|
| Onboarding | 3-page intro carousel (shown once) |
| Login/Register | Email + Google auth with validation and friendly error messages |
| Home (Garden) | Styled garden view, greeting, streak, weekly summary, connectivity banner |
| Log Mood | Mood selector, text input, photo/video attachment, success animation |
| History | List + calendar views with mood filters, shimmer loading, sync icons |
| Entry Detail | Full entry view with Hero animation, edit/delete |
| Settings | Profile, dark mode, animation speed, notifications, sync status, logout, delete account |

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
├── app.dart                  # MaterialApp, routes, theme mode, startup logic
├── config/
│   ├── theme.dart            # Light + dark theme, color palettes, typography
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
│   ├── mood_provider.dart    # Mood entries, save/edit/delete, streak, sync status
│   ├── garden_provider.dart  # Garden elements from mood data
│   └── settings_provider.dart# Animation speed, notifications, dark mode
├── screens/                  # All app screens
├── widgets/
│   ├── mood_chip.dart        # Animated mood selector chip
│   ├── mood_card.dart        # Entry list card with Hero and sync indicator
│   ├── garden_element.dart   # Base animated garden element
│   ├── garden_plant.dart     # Styled plant container with growth animation
│   ├── garden_bug.dart       # Bug container with fade animation
│   ├── garden_ground.dart    # Sky/ground gradient background
│   ├── connectivity_banner.dart # Offline status banner
│   ├── sync_indicator.dart   # Cloud/local sync icon
│   ├── success_animation.dart# Post-save bloom animation overlay
│   ├── attachment_preview.dart# Photo/video preview
│   ├── confirmation_dialog.dart # Reusable confirmation dialog
│   └── streak_badge.dart     # Streak counter display
└── utils/
    ├── error_handler.dart    # Centralized Firebase error message mapping
    ├── date_helpers.dart     # Date formatting, streak calculation
    ├── validators.dart       # Email/password validation
    ├── sync_manager.dart     # Offline sync logic
    └── responsive.dart       # Responsive layout utilities
```

**State Management:** Provider (ChangeNotifier pattern)

**Data Flow:**
1. User actions trigger Provider methods
2. Providers call Services (Firebase, SQLite, SharedPreferences)
3. UI rebuilds via `context.watch<Provider>()`

**Offline Strategy:**
- Mood entries save to local SQLite first, then sync to Firestore
- Unsynced entries push to Firestore when connectivity is restored
- Connectivity banner shows offline status in real-time
- Settings stored in SharedPreferences (no cloud sync)

---

## Testing

### Run all unit and widget tests
```bash
flutter test
```

### Run integration tests on Android
```bash
flutter test integration_test/app_test.dart
```

### Run integration tests on Chrome
```bash
flutter test integration_test/app_test.dart -d chrome
```

### Test files
| Test | What it covers |
|------|---------------|
| `test/models/mood_entry_test.dart` | Model serialization (Firestore + SQLite roundtrip) |
| `test/models/mood_type_test.dart` | Enum values, categories, fromString |
| `test/utils/validators_test.dart` | Email, password, display name validation |
| `test/utils/date_helpers_test.dart` | Date formatting, streak calculation, week days |
| `test/utils/error_handler_test.dart` | Firebase auth, storage, Firestore error code mappings |
| `test/providers/settings_provider_test.dart` | Dark mode toggle, animation speed, persistence |
| `test/widgets/mood_chip_test.dart` | Render, selection state, tap callback |
| `test/widgets/mood_card_test.dart` | Mood display, text preview, attachment icons |
| `test/widgets/confirmation_dialog_test.dart` | Title/message display, confirm/cancel returns |
| `test/widgets/garden_element_test.dart` | Plant/bug rendering, opacity fading, garden generation |
| `integration_test/app_test.dart` | Settings persistence, mood CRUD, garden provider |

---

## Design System

### Light Theme
| Token | Color | Hex |
|-------|-------|-----|
| Primary | Forest Green | `#4A7C59` |
| Primary Light | Sage Green | `#6B9F7A` |
| Secondary | Dusty Rose | `#C27A8A` |
| Accent | Warm Gold | `#E8B954` |
| Background | Warm Off-White | `#FAF8F5` |
| Card | Light Cream | `#F5F0EB` |

### Dark Theme
| Token | Color | Hex |
|-------|-------|-----|
| Primary | Sage Green | `#6B9F7A` |
| Secondary | Soft Rose | `#D4A0AB` |
| Accent | Warm Gold | `#E8B954` |
| Background | Dark Navy | `#1A1A2E` |
| Surface | Dark Card | `#242438` |
| Card | Slightly Lighter | `#2D2D44` |

**Typography:** Nunito (headings), Inter (body) via Google Fonts

---

## Version History

| Version | Sprint | Status | Key Changes |
|---------|--------|--------|-------------|
| v0.1 Alpha | S1-S2 | Complete | Core screens, auth, CRUD, SQLite, basic garden |
| v0.2 Beta | S3 | Complete | Dark mode, garden upgrade, integration tests, error handling |
| v1.0 Final | S4 | Complete | Full test coverage, code quality polish, performance optimization, security hardening |

---

## Test Coverage

See [`test/TEST_COVERAGE.md`](test/TEST_COVERAGE.md) for the complete test-to-feature mapping.

| Category | Count | Status |
|----------|-------|--------|
| Unit Tests (models) | 15 tests | All passing |
| Unit Tests (utils) | 30+ tests | All passing |
| Unit Tests (providers) | 35+ tests | All passing |
| Unit Tests (services) | 18 tests | All passing |
| Widget Tests | 20+ tests | All passing |
| Integration Tests | 8+ flows | All passing |
| **Total** | **168 tests** | **All passing** |

### Run Tests

```bash
# All unit + widget tests
flutter test

# With expanded output
flutter test --reporter expanded

# Integration tests (Android)
flutter test integration_test/app_test.dart

# Integration tests (Chrome)
flutter test integration_test/app_test.dart -d chrome

# Static analysis (zero warnings)
flutter analyze
```

---

## Security

- Firestore security rules enforce per-user data isolation (`firestore.rules`)
- Firebase Storage rules limit uploads to 5MB per file (`storage.rules`)
- No API keys or credentials in source code (Firebase config via `flutterfire configure`)
- SharedPreferences used only for non-sensitive settings (dark mode, animation speed)
- Auth error messages are user-friendly (no raw Firebase codes exposed)

---

## Evidence Package

Test execution logs and screenshots are stored in the `evidence/` folder.

### Capture evidence

```bash
bash scripts/capture_evidence.sh
```

### Screenshots to capture

1. App running on Android emulator (Home, Log Mood, History, Settings)
2. App running on Chrome browser (same 4 screens)
3. Test output showing all tests passing

---

## Beta v0.2 Changes

- **Dark Mode** - Full dark theme wired to settings toggle with custom dark palette
- **Garden Upgrade** - Styled Container widgets for plants/bugs with growth and fade animations
- **Error Handler** - Centralized user-friendly error messages for Firebase auth, storage, Firestore
- **Connectivity Banner** - Real-time offline status banner using connectivity_plus
- **Sync Status** - Cloud/local icons on mood cards, pending count and "Sync Now" in settings
- **Hero Animations** - Mood emoji animates between History and Entry Detail screens
- **Page Transitions** - Fade-through transitions for screen navigation
- **Success Animation** - Particle + checkmark overlay when saving a mood
- **Shimmer Loading** - Placeholder cards in History while loading
- **Pull-to-Refresh** - Themed refresh indicator with primary color

## Final v1.0 Changes

- **Full Test Coverage** - 168 tests across unit, widget, and integration levels
- **Test-to-Feature Mapping** - `test/TEST_COVERAGE.md` maps every feature to its tests
- **New Tests** - garden_provider, local_db_service, sync_manager, dark mode, delete, filter
- **Dartdoc Comments** - All public APIs in services/, providers/, models/, utils/
- **Zero Lint Warnings** - `flutter analyze` returns no issues
- **Consistent Snackbars** - Green success / red error snackbars with icons and timed duration
- **Web Hover Effects** - Hover feedback on mood cards for desktop/web
- **Security Rules** - Firestore + Storage rules documented and version controlled
- **Evidence Package** - Capture script and evidence folder for submission

---

## Known Limitations

- Push notifications: setting persists but delivery requires platform-specific setup (FCM for Android, not supported on Web)
- Garden assets: styled containers with animations (custom SVG illustrations are a future enhancement)
- Video camera recording: not supported on Web due to browser limitations (gallery pick works)
- Offline sync: uses eventual consistency with last-write-wins conflict resolution
- Data export: not yet implemented (planned for future version)

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
