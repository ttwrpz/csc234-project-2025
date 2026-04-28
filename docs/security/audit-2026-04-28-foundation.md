# Security Review — PR `feat/1.1-foundation-restructure`

**Reviewer:** security-reviewer agent
**Date:** 2026-04-28
**Sprint:** S2 Day 1 EOD
**Scope:** Foundation restructure audit. Files reviewed:
- `apps/mobile/lib/firebase_options.dart`
- `firebase/firestore.rules`
- `firebase/storage.rules`
- `firebase.json`
- `.claude/hooks/settings.json`
- `apps/mobile/pubspec.yaml`
- `docs/adr/0001-repo-structure-and-clean-architecture.md`

## Findings

### 🔴 Critical (block merge)
None.

### 🟠 High (block merge unless explicitly waived)
None.

### 🟡 Medium (fix in Sprint 2 follow-up)

- **[R-001] Web API key has no HTTP referrer restriction (assumed).** Location: `apps/mobile/lib/firebase_options.dart:50` (`AIzaSyBEeN6AbPk3k5lTvx3j1ASnNzUeRbEYNeY`). Public-by-design Firebase web API keys are acceptable to commit per Google's official guidance, but only when GCP Console restrictions are in place. Without an HTTP referrer allowlist, an attacker who scrapes the key from the GitHub repo can use it from any origin to enumerate/abuse Firebase services billed to the project (Firestore reads, Identity Toolkit signups burning the free tier, Cloud Storage download URLs). **Remediation: Theerawat to add an HTTP referrer restriction in GCP Console → APIs & Services → Credentials → "Browser key (auto created by Firebase)" before Sprint 2 close (2026-05-12).** Allowlist: `localhost:*`, `127.0.0.1:*`, and the production domain (TBD — placeholder until Sprint 5 web hosting). Document the restriction in `docs/security/api-key-restrictions.md`.

- **[R-002] Android API key has no app restriction (assumed).** Location: `apps/mobile/lib/firebase_options.dart:60` (`AIzaSyCTnAdALXiDfJcKTvgLl-ZcdSNxJSDB308`). Same exposure profile as R-001 but the mitigation is an Android app restriction (SHA-1 + package name) rather than HTTP referrer. **Remediation: Theerawat to add Android app restriction in GCP Console allowlisting the debug SHA-1 and package name `com.cssit.usercentricapp` before Sprint 2 close.** Capture both debug-keystore SHA-1 and the team's CI keystore SHA-1 (when CI signing is set up). Note: Sprint 3 ADR-0002 plans a package id rename to `com.moodbloom.app`; restriction must be updated then or wiring breaks.

- **[R-003] iOS API key has no app restriction (assumed).** Location: `apps/mobile/lib/firebase_options.dart:68` (`AIzaSyDgaNX-sMVA8c0qGr3B_17qpBcLtlJ7VH0`). MoodBloom is Android+Web only per CLAUDE.md, but the iOS config is still embedded and reachable. **Remediation: Theerawat to either (a) add iOS app restriction allowlisting bundle id `com.cssit.usercentricapp`, or (b) delete the iOS app from the Firebase project entirely and regenerate `firebase_options.dart` to drop the `ios` block.** Option (b) is preferred — it shrinks the attack surface and aligns with the locked stack. If (b) is chosen, this is `flutterfire configure` work which is gated by the hook deny-list and must be coordinated with the architect under ADR-0002.

- **[R-004] Confirm none of the three keys is a server-side / Cloud Functions key.** Action: **Theerawat to verify in GCP Console that all three keys listed in `firebase_options.dart` are categorized "Browser key" or "Android key" or "iOS key" — never "Server key" or "unrestricted".** A server-side Gemini/Firebase Admin SDK key in the client bundle would be Critical. This is an evidence-gathering step, not yet a finding. Confirmation goes in `docs/security/api-key-restrictions.md`.

### 🟢 Low / informational

- **[R-005] Hook bypass strategy: B3 (status quo).** The `secret-scan` preWrite hook regex `AIza[A-Za-z0-9_-]{35}` at `.claude/hooks/settings.json:27` matches the three Firebase keys in `firebase_options.dart:50,60,68`. Recommendation: **adopt B3 (status quo).** Justification:
  - **B1 (path allowlist)** weakens the hook for an entire file path; future drift in that file (e.g., a stray Gemini server key accidentally pasted in by an agent during S3) would not be caught.
  - **B2 (regex tightening)** is the most dangerous — it would require fingerprinting Firebase keys vs other `AIza...` keys (Google Maps, Gemini, etc.) and Google does not document a stable distinguisher. Real secrets would slip through.
  - **B3 (status quo)** treats `firebase_options.dart` as touch-only-via-`flutterfire configure` (which is already in the deny list — an architect+security-reviewer waiver is required to run it). The file is generated, not hand-edited; agents have no business `Write`-ing it. The current commit was made via `git mv` (history-preserving) plus an `Edit` to strip `databaseURL` lines — neither operation triggers the preWrite hook on new content. This is the right behavior.
  - Add a one-line note to `CLAUDE.md` "Do-not-do list" reading: `apps/mobile/lib/firebase_options.dart` — generated; never `Write`, only `flutterfire configure` regenerates it (architect + security-reviewer waiver required, per ADR-0001 and ADR-0002).
  - Per CLAUDE.md "Do-not-do list", any change to `.claude/hooks/settings.json` requires a team meeting. B3 requires no hook change, so no meeting needed. B1 and B2 would each require a team meeting before adoption.

- **[R-006]** Firestore rules stub at `firebase/firestore.rules:4` uses `match /users/{uid}/{document=**}`. The `{document=**}` recursive wildcard does cover the `users/{uid}` document itself. The auth guard at `firestore.rules:5` correctly tests both `request.auth != null` and `request.auth.uid == uid`. Rules version `'2'` confirmed at line 1. **Stub is correct for S2.** Real rules with `diff().affectedKeys()`, `request.time` immutability, and 24h `updatedAt` window land in WBS 2.3 / S3.

- **[R-007]** Storage rules at `firebase/storage.rules:5` are `allow read, write: if false;` under `match /{allPaths=**}`. Default-deny confirmed. **Correct for S2.**

- **[R-008]** `firebase.json` paths verified — `firestore.rules`, `storage.rules`, `flutter.platforms.android.default.fileOutput`, `flutter.platforms.dart` key all correctly reflect the `apps/mobile/` move.

- **[R-009]** `.claude/hooks/settings.json` integrity: `git log` shows zero commits since `885e6d7` (Initial commit). **Byte-identical confirmed.** All matcher path-bindings (`*.dart`, `apps/mobile/lib/**/*.dart`, `apps/mobile/lib/features/**/domain/**/*.dart`) bind correctly under the new layout. No matcher mis-fires.

- **[R-010] Pin Firebase / Auth package versions (fix S2 hardening or S3 start).** `apps/mobile/pubspec.yaml` uses `^` ranges on `firebase_auth ^6.1.3`, `cloud_firestore ^6.1.1`, `firebase_core ^4.3.0`, `google_sign_in ^6.2.2`. CLAUDE.md says "Package versions are pinned (no `^` ranges on security-sensitive packages like auth, crypto, http clients)". Not blocking S2 because `pubspec.lock` pins transitively, but for defense-in-depth against malicious patch releases (cf. `node-ipc` 2022) drop the `^`. Also flag `firebase_auth ^6.x` — major version 6 is recent; verify migration guide compliance before pinning.

- **[R-011]** `databaseURL` strip confirmed. Zero matches in `firebase_options.dart`. Architect's required cleanup landed.

- **[R-012]** Secret scan over `apps/mobile/` returned only the three documented Firebase `AIza...` keys and zero matches for `sk-`, `xox*-`, `ghp_`, `AKIA` patterns. Clean modulo the documented exception.

## Cleared

- Firestore rules: ✅ (S2 stub correct; real rules deferred to WBS 2.3)
- Storage rules: ✅ (default-deny)
- `firebase.json` path correctness: ✅
- Hooks integrity: ✅ (byte-identical, no matcher mis-fires)
- Secret scan: ✅ (modulo documented `firebase_options.dart` exception with accompanying R-001/R-002/R-003 remediations)
- Dependency forbidden-package check: ✅
- `databaseURL` strip: ✅
- Cloud Functions: N/A (empty in S2)
- Auth flow: N/A (no auth code yet in S2)
- PII in logs: N/A (no logger calls yet in S2)

## Sign-off

- [x] ⚠️ **Approved with conditions.** R-001 through R-004 are GCP Console actions for Theerawat to complete and document in `docs/security/api-key-restrictions.md` before Sprint 2 close (2026-05-12). They do not block this PR's merge because (a) the keys are public-by-design and (b) no client code yet exercises Firebase APIs, so the abuse window is bounded by the time-to-restriction. R-010 (pin auth/firebase package versions) is a fix-next-sprint follow-up. R-005 hook bypass strategy: adopt B3 (status quo) — no hook change, no team meeting needed; add a CLAUDE.md note clarifying `firebase_options.dart` is generated-only.

**Merge of `feat/1.1-foundation-restructure` is approved.** Track R-001..R-004 in the Sprint 2 backlog as a single ticket "S2 Hardening: Firebase API key console restrictions" assigned to Theerawat, due 2026-05-12.
