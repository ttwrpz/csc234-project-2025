# DevOps follow-ups for production deploy

**Status:** Open through v1.5; **must close before any production deploy**.
**Owner:** DevOps lead (project Theerawat for academic deploy; whoever takes the post-graduation production hand-off).
**Authored:** Sprint 5 Day 1 background (per S5 plan §3a.5).
**Last reviewed:** 2026-05-07.

This runbook tracks the operational items that **cannot be closed by code agents working from source**. Each item is real, traceable to a security audit finding, and outside the scope of the v1.5 academic release. They live here so they don't get lost between the v1.5 demo and any future production cut, and so the Enterprise Audit Report's "operational follow-ups" appendix has a single citation.

If any item flips to `Closed`, update this doc — do not delete the row.

---

## Index

| # | Item | Severity | Source | Status |
|---|---|---|---|---|
| R-M01 | Firestore TTL on rate-limit collections | MEDIUM | Cloud Function audit (`docs/security/audit-2026-05-12-v1.0.md` §1.3) | Open |
| R-M02-IAM | Secret Manager IAM scoping for `GEMINI_API_KEY` | MEDIUM | Cloud Function audit (`docs/security/audit-2026-05-12-v1.0.md` §1.4) | Code-side ✅ / IAM half open |
| R-3 | `firebase deploy --only firestore:rules` confirmation | HIGH (deploy-only) | Drift chain audit (S3 retro action item 2) | Open |
| AC-PROV | App Check provider config (Play Integrity / reCAPTCHA Enterprise) | HIGH (deploy-only) | CLAUDE.md "Stack (locked)" + S5 plan §11 risk #4 | Open |

---

## R-M01 — Firestore TTL on rate-limit collections

**Severity:** MEDIUM. Without TTL, the `rateLimits/*` collections grow unboundedly — every uid that hits any rate-limited Cloud Function leaves a doc that sits forever. Bounded cost (one doc per uid per limiter) but never decays.

**Affected paths:**

- `rateLimits/{uid}` — used by `analyzeMoodText` (10 calls / 60 s window). Field: `expireAt: timestamp`.
- `rateLimits.patterns/{uid}` — used by `analyzePatterns` (1 call / 30 s window). Field: `expireAt: timestamp`.
- `rateLimits/cheerUp/{uid}` — used by `sendCheerUpPush` (1 call / 24 h window) — **lands in v1.5 5.5b**. Field: `expireAt: timestamp`.

**What to do:**

1. Open Firebase Console → Firestore Database → Indexes → TTL.
2. Add a TTL policy on `rateLimits` with TTL field `expireAt`.
3. Add a TTL policy on `rateLimits.patterns` with TTL field `expireAt`.
4. Add a TTL policy on `rateLimits/cheerUp` with TTL field `expireAt`. **Only after v1.5 5.5b ships and the collection is non-empty** — TTL on an empty collection is a no-op but Firebase Console will warn.

**How to verify:**

```bash
gcloud firestore operations list --project=<PROJECT_ID> --filter="metadata.@type:type.googleapis.com/google.firestore.admin.v1.UpdateTtlMetadata"
```

Should list three completed `UpdateTtlMetadata` operations. Or sample a doc whose `expireAt` is in the past — should disappear within 24 hours of the policy applying.

**Why it's not in code:** Firestore TTL is a console-only configuration; not in `firestore.rules` or any deployed artifact.

---

## R-M02-IAM — Secret Manager IAM scoping

**Severity:** MEDIUM. The Gemini API key lives in Secret Manager and is bound at function init via `defineSecret('GEMINI_API_KEY')` (verified by `analyzeMoodText.test.ts` case #14 — "secret loaded via defineSecret, never via process.env"). The code-side posture is already correct. **The IAM scoping — that only the Cloud Functions runtime service account can read the secret — is a console step that source can't enforce.**

**Code-side closed:** v1.0.1 commit (`d1eaa1df`) raised `enforceAppCheck: true` on `analyzeMoodText`; both Gemini-touching CFs now refuse non-attested clients.

**IAM-side open:**

1. Open Google Cloud Console → IAM & Admin → Service Accounts.
2. Identify the Cloud Functions runtime service account (typically `<project-number>-compute@developer.gserviceaccount.com` or a project-specific `cloud-functions-sa@...`).
3. Open Secret Manager → `GEMINI_API_KEY` → Permissions.
4. Confirm only the Cloud Functions runtime SA has the `roles/secretmanager.secretAccessor` role. Remove any human users, default editors, or other service accounts that have inherited the role.

**How to verify:**

```bash
gcloud secrets versions access latest --secret=GEMINI_API_KEY \
  --impersonate-service-account=<NON_RUNTIME_SA_EMAIL>
# Expected: ERROR: (gcloud.secrets.versions.access) PERMISSION_DENIED
```

A non-runtime principal must return `403`. If any non-runtime principal returns the secret, remove its grant.

**Block production deploy if any check fails.**

---

## R-3 — `firebase deploy --only firestore:rules` confirmation

**Severity:** HIGH (deploy-only). The hardened `firestore.rules` (per-user RBAC, immutable `createdAt`, 24-hour mutability gate, field-level validation via `diff().affectedKeys()`) live in `firebase/firestore.rules` and pass 15+ emulator tests in CI on every PR. **They are NOT automatically deployed to the Firebase project.** Anyone running the app against the live Firebase project is hitting whatever rules were last manually pushed — possibly the open-permission default rules from project creation.

**What to do (every time `firestore.rules` changes):**

```bash
cd C:/Users/user/Desktop/FlutterProjects/csc234-project-2025
firebase deploy --only firestore:rules --project=<PROJECT_ID>
```

**How to verify:**

1. Firebase Console → Firestore Database → Rules → confirm the rules text matches `firebase/firestore.rules` HEAD on `main`.
2. The rules tab shows the timestamp of the last push and the deployer's email — both should be recent and project-team.
3. Try a deny-by-default request from the rules playground (e.g. read `users/{some_other_uid}/moods/{some_id}` as a different uid). Must return `permission_denied`.

**v1.5 cadence:** the S5 5.5b PR adds `match /cheerUpEvents/{evtId}`, `match /interventionState/{docId}`, and `match /settings/{settingId}` blocks. After that PR merges, **redeploy rules** before the demo or any live-Firebase test.

**v1.5 PR-gate:** the PR template (`.github/PULL_REQUEST_TEMPLATE.md`) "Security review" section asks reviewers to confirm whether `firestore.rules` is touched. Use that signal to remember R-3.

---

## AC-PROV — App Check provider config

**Severity:** HIGH (deploy-only). `enforceAppCheck: true` is set on `analyzeMoodText`, `analyzePatterns`, and (in v1.5) `deleteAccount`. Without a provider configured in the Firebase Console, the app cannot mint tokens and every callable will return `unauthenticated`. Debug builds use the SDK's `debugProvider` (which auto-registers a debug token); production builds must use a real provider.

**What to do:**

1. **Android:** Firebase Console → Project Settings → App Check → Apps → Android app → enroll Play Integrity provider. Requires the app's SHA-256 signing cert fingerprint; pull from `apps/mobile/android/app/build.gradle` signing config. Submit to Google Play Console for SafetyNet → Play Integrity migration if not already done.
2. **Web:** Firebase Console → Project Settings → App Check → Apps → Web app → enroll reCAPTCHA Enterprise provider. Requires a reCAPTCHA Enterprise site key from Google Cloud Console → Security → reCAPTCHA Enterprise.
3. **Debug:** keep `debugProvider` for local emulator runs; the provider config is per-environment.

**How to verify:**

After provider config:

1. Run a release build (`flutter build apk --release` for Android, `flutter build web --release` for Web).
2. Sign in.
3. Trigger an AI mood detection from the Log screen.
4. Cloud Functions logs show `outcome: 'success'`, NOT `outcome: 'app_check_failed'`.

If the production build returns `app_check_failed`, the provider config is missing or the signing cert / site key is wrong.

**v1.5 release impact:** the v1.5 academic demo runs in a project where App Check enforcement is on. If the demo presenter signs in and gets `unauthenticated` errors, the provider config is the most likely cause. Pre-demo smoke check (Day 5 morning) must include an AI mood detection with App Check active.

---

## How this doc relates to the audit report

The Enterprise Audit Report (`docs/audit/enterprise-audit-report.md`) §3.8 "Open follow-ups for production deploy" lists these four items as a single citation back to this runbook. Updating one updates the other only at finalize-time (Sprint 5 Day 5).

## Closure protocol

When an item flips to `Closed`:

1. Update the row's status to `Closed (YYYY-MM-DD)`.
2. Add a one-line note under the item describing what was done and by whom.
3. Do **not** delete the row — the audit history matters.

If a new operational item surfaces (e.g. a new Cloud Function adds a new rate-limit collection), add a new row with the same template.
