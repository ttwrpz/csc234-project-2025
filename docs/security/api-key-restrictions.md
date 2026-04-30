# Firebase API Key Restrictions — Console Action Tracker

**Owner:** Theerawat (Lead)
**Due:** 2026-05-12 (Sprint 2 close)
**Source:** Risk register R-001..R-004 in `docs/security/audit-2026-04-28-foundation.md`

The three API keys in `apps/mobile/lib/firebase_options.dart` are public-by-design Firebase client keys. They are acceptable to commit IF and ONLY IF GCP Console restrictions are in place. This document tracks the restrictions and confirms they are applied.

## Key inventory

| Key | Location | Type | Restriction needed | Status |
|---|---|---|---|---|
| `AIzaSyBEeN6AbPk3k5lTvx3j1ASnNzUeRbEYNeY` | `firebase_options.dart:50` (Web) | Browser key | HTTP referrer allowlist | ☐ |
| `AIzaSyCTnAdALXiDfJcKTvgLl-ZcdSNxJSDB308` | `firebase_options.dart:60` (Android) | Android key | SHA-1 + package id | ☐ |
| `AIzaSyDgaNX-sMVA8c0qGr3B_17qpBcLtlJ7VH0` | `firebase_options.dart:68` (iOS) | iOS key | Bundle id allowlist OR delete iOS app | ☐ |

## Action items

### R-001 — Web API key HTTP referrer restriction

GCP Console → APIs & Services → Credentials → "Browser key (auto created by Firebase)" → Application restrictions → HTTP referrers. Allowlist:
- `localhost:*`
- `127.0.0.1:*`
- (Sprint 5 production domain — TBD)

API restrictions: limit to Firebase services only (Identity Toolkit, Firestore, Storage, Realtime Database — though we don't use RTDB, leaving it out is fine).

### R-002 — Android API key app restriction

GCP Console → APIs & Services → Credentials → "Android key (auto created by Firebase)" → Application restrictions → Android apps. Add:
- Package name: `com.cssit.usercentricapp`
- SHA-1: (debug keystore — run `cd apps/mobile/android && ./gradlew signingReport` to get it)
- (CI keystore SHA-1 — when CI signing is set up in S3)

**Note:** Sprint 3 ADR-0002 plans a package id rename to `com.moodbloom.app`. This restriction must be updated alongside that rename.

### R-003 — iOS API key

**Recommendation:** Option (b) — delete the iOS app from the Firebase project entirely. MoodBloom is Android + Web only per CLAUDE.md.

To delete: Firebase Console → Project Settings → Your apps → iOS app → Remove this app. Then re-run `flutterfire configure` (architect + security-reviewer waiver required, per ADR-0001) to regenerate `firebase_options.dart` without the `ios` block.

If keeping the iOS app for any reason, add an iOS app restriction allowlisting bundle id `com.cssit.usercentricapp` instead.

### R-004 — Verify no server-side keys

For each of the three keys above, GCP Console → APIs & Services → Credentials. Confirm the key type is "Browser key" / "Android key" / "iOS key" — never "Server key" or "unrestricted". A server-side key (Firebase Admin SDK, Gemini API key for Cloud Functions) embedded in the client would be Critical.

## Confirmation log

| Date | Action | Confirmed by |
|---|---|---|
| 2026-04-28 | Risk register R-001..R-004 raised in Day 1 EOD audit | security-reviewer |
| | (Theerawat to fill in as actions complete) | |
