# Test Coverage Mapping

Maps every committed feature to its corresponding test file and test type.

## Feature-to-Test Mapping

| Feature | Function ID | Test File | Test Type |
|---------|------------|-----------|-----------|
| Email Registration | F01 | `utils/validators_test.dart`, `providers/settings_provider_test.dart` | Unit |
| Email Login | F02 | `utils/validators_test.dart` | Unit |
| Google Sign-In | F03 | (requires Firebase mock; covered in integration) | Integration |
| Password Reset | F04 | (requires Firebase mock; UI validated via validators) | Unit |
| Sign Out | F05 | `integration_test/app_test.dart` | Integration |
| Delete Account | F06 | `integration_test/app_test.dart` | Integration |
| Password Strength Indicator | F07 | `utils/validators_test.dart` | Unit |
| Mood Selection (10 Types) | F08 | `models/mood_type_test.dart`, `widgets/mood_chip_test.dart` | Unit, Widget |
| Mood Text Input | F09 | `integration_test/app_test.dart` | Integration |
| Photo Attachment | F10 | `integration_test/app_test.dart` | Integration |
| Video Attachment | F11 | `integration_test/app_test.dart` | Integration |
| Mood Model Serialization | F12 | `models/mood_entry_test.dart` | Unit |
| Mood CRUD (Create) | F13 | `integration_test/app_test.dart` | Integration |
| Mood CRUD (Update) | F14 | `integration_test/app_test.dart` | Integration |
| Living Garden Canvas | F15 | `widgets/garden_element_test.dart`, `providers/garden_provider_test.dart` | Widget, Unit |
| Plant Growth Animation | F16 | `widgets/garden_element_test.dart` | Widget |
| Bug Fade Animation | F17 | `widgets/garden_element_test.dart`, `providers/garden_provider_test.dart` | Widget, Unit |
| Streak Calculation | F18 | `utils/date_helpers_test.dart` | Unit |
| Date Formatting | F19 | `utils/date_helpers_test.dart` | Unit |
| Mood History List View | F20 | `widgets/mood_card_test.dart` | Widget |
| Mood Calendar View | F21 | `integration_test/app_test.dart` | Integration |
| Mood Filter Chips | F22 | `integration_test/app_test.dart` | Integration |
| Entry Detail View | F23 | `integration_test/app_test.dart` | Integration |
| Delete Entry | F24 | `integration_test/app_test.dart` | Integration |
| Edit Entry | F25 | `integration_test/app_test.dart` | Integration |
| Confirmation Dialog | F26 | `widgets/confirmation_dialog_test.dart` | Widget |
| Error Message Mapping | F27 | `utils/error_handler_test.dart` | Unit |
| Dark Mode Toggle | F28 | `providers/settings_provider_test.dart`, `integration_test/app_test.dart` | Unit, Integration |
| Animation Speed Setting | F29 | `providers/settings_provider_test.dart`, `integration_test/app_test.dart` | Unit, Integration |
| Notifications Toggle | F30 | `providers/settings_provider_test.dart` | Unit |
| Onboarding Seen Persistence | F31 | `providers/settings_provider_test.dart` | Unit |
| Settings Persistence | F32 | `providers/settings_provider_test.dart`, `integration_test/app_test.dart` | Unit, Integration |
| Email Validation | F33 | `utils/validators_test.dart` | Unit |
| Password Validation | F34 | `utils/validators_test.dart` | Unit |
| SQLite Local Cache | F35 | `services/local_db_service_test.dart` | Unit |
| Offline-First Save | F36 | `services/local_db_service_test.dart`, `utils/sync_manager_test.dart` | Unit |
| Automatic Background Sync | F37 | `utils/sync_manager_test.dart` | Unit |
| Sync Status Indicators | F38 | `widgets/mood_card_test.dart` | Widget |
| Connectivity Banner | F39 | (widget uses live connectivity stream) | Manual |
| Garden Element Positioning | F40 | `providers/garden_provider_test.dart` | Unit |
| Garden Mood-to-Element Mapping | F41 | `providers/garden_provider_test.dart`, `widgets/garden_element_test.dart` | Unit, Widget |
| Success Animation | F42 | (overlay widget; manual UI verification) | Manual |
| Shimmer Loading | F43 | (widget uses shimmer package; manual UI verification) | Manual |
| Hero Transitions | F44 | (framework animation; manual UI verification) | Manual |
| Responsive Layout (Web) | F45 | (responsive utilities; verified via cross-platform run) | Manual |

## Test Summary

| Category | File Count | Test Count | Status |
|----------|-----------|------------|--------|
| Unit Tests (models) | 2 | 15 | All passing |
| Unit Tests (utils) | 3 | 30+ | All passing |
| Unit Tests (providers) | 2 | 15+ | All passing |
| Unit Tests (services) | 2 | 15+ | All passing |
| Widget Tests | 4 | 15+ | All passing |
| Integration Tests | 1 | 8+ | All passing |

## How to Run

```bash
# All unit + widget tests
flutter test

# Specific test file
flutter test test/providers/garden_provider_test.dart

# Integration tests (Android)
flutter test integration_test/app_test.dart

# Integration tests (Web)
flutter test integration_test/app_test.dart -d chrome

# With expanded output
flutter test --reporter expanded
```
