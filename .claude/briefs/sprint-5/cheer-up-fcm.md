# Handoff Brief — Cheer-Up Loop + FCM Push (HB-003)

**WBS:** 5.5 (Cheer-Up Intervention — copy parity, cooldown writes, sendCheerUpPush CF, 10-day footer)
**Sprint:** S5
**Day:** Day 1 afternoon (5.5a) → Day 2 (5.5b + 5.5c)
**Target branch:** `feat/5.5-cheer-up-fcm`
**Owner:** flutter-engineer (Kraiwich), with security-reviewer audit Day 2 PM
**Related:** ADR-0007 (statistical-primary insights, PII fence pattern reused here); ADR-0008 (intervention-cooldown persistence — written alongside this brief); CLAUDE.md pivot feature #5; Sprint-5 plan §4

## Goal

Close the cheer-up loop end-to-end. Sprint 4 shipped the pure-Dart detector, the Freezed `InterventionState` entity, the `CheerUpBanner` widget, the `BreathingOverlay`, and the `HotlineFooter` widget — but none of them write persistence and none of them surface a push notification. This brief delivers three concrete sub-tracks:

- **5.5a (Day 1 afternoon)** — Banner copy parity audit + cooldown writes via a new `CheerUpController` Riverpod controller. The detector's `triggered` event becomes a persisted anchor pair (`lastTriggeredAt`, `firstTriggeredAt`).
- **5.5b (Day 2 morning)** — `sendCheerUpPush` Cloud Function fires a single FCM multicast on the day's first trigger, governed by an idempotent event-doc id, a 24h rate limit, and a fixed payload (no PII, no clinical language, no hotline copy in the body).
- **5.5c (Day 2 afternoon)** — Wire the existing `HotlineFooter` to `firstTriggeredAt + 10d` so the 10-day escalation surfaces in-app only.

The architectural decisions for cooldown topology are locked in **ADR-0008**. The Cloud Function pattern is mirrored from `analyzePatterns.ts` (validation order, logger allowlist) and **ADR-0003**. Read both before opening any file.

## State of the world (S4 carry-over)

| Surface | File | Status entering S5 |
|---|---|---|
| Pure detector | `apps/mobile/lib/features/garden/domain/pattern_detector.dart` | Complete; pure-Dart; honours cooldown + escalation gates |
| State entity | `apps/mobile/lib/features/garden/domain/entities/intervention_state.dart` | Complete; `triggered`, `escalated`, `reason` |
| Anchor storage | `apps/mobile/lib/features/garden/data/intervention_state_storage.dart` | SharedPreferences only; reads + writes + `maybeClearFirstTriggeredAt` |
| Provider | `apps/mobile/lib/features/garden/data/providers.dart` `interventionStateProvider` | Read path wired; **never writes anchors today** |
| Banner UI | `apps/mobile/lib/features/garden/presentation/widgets/cheer_up_banner.dart` | Renders + opens overlay; **does not call any cooldown write** |
| Garden host | `apps/mobile/lib/features/garden/presentation/garden_screen.dart:39-103` | `_bannerDismissed` is an in-state ad-hoc bool; never anchors persist |
| Breathing overlay | `apps/mobile/lib/features/garden/presentation/widgets/breathing_overlay.dart` | Complete; 4-7-8 timer |
| Hotline footer | `apps/mobile/lib/features/garden/presentation/widgets/hotline_footer.dart` | Renders gate-conditional; conditional in `garden_screen.dart:203-207` |
| FCM (any) | — | Absent; `firebase_messaging` not in `pubspec.yaml` |
| Notifications feature | `apps/mobile/lib/features/notifications/` | Absent |

## Sequence (canonical)

```mermaid
sequenceDiagram
    participant U as User
    participant App as MoodBloomApp
    participant Det as detectPattern (pure)
    participant Ctrl as CheerUpController
    participant Repo as InterventionStateRepository
    participant Cache as SharedPreferences (offline mirror)
    participant Cloud as Firestore users/{uid}/...
    participant CF as sendCheerUpPush CF
    participant FCM as FCM multicast
    participant Banner as CheerUpBanner

    Note over App: log mood / open Home
    App->>Det: entries + now + anchors (from Repo)
    Det-->>App: triggered=true, reason
    App->>Ctrl: onShown() — first time this lifecycle
    Ctrl->>Repo: writeLastTriggeredAt(now)
    Ctrl->>Repo: writeFirstTriggeredAtIfNull(now)
    Repo->>Cache: mirror anchors (offline-read path)
    Repo->>Cloud: users/{uid}/interventionState (Firestore source-of-truth)
    Ctrl->>Cloud: users/{uid}/cheerUpEvents/{dayUtc}-{reason} (idempotent create)
    Note over Cloud,CF: onDocumentCreated trigger
    CF->>Cloud: read users/{uid}/settings/notifications (enabled? tokens?)
    CF->>Cloud: rateLimits/cheerUp/{uid} consumeToken (24h, max 1)
    alt allowed && enabled && tokens non-empty
        CF->>FCM: sendEachForMulticast(tokens, fixed payload, channelId='cheer_up')
        FCM-->>U: notification (platform delivers)
    else opted_out / rate_limited / no_tokens
        CF->>logger: outcome=opted_out|rate_limited|no_tokens (no PII)
    end
    par in-app
        App->>Banner: render with reason
        U->>Banner: tap "Try it"
        Banner->>App: showDialog(BreathingOverlay)
    end
    Note over App,Repo: detector reads firstTriggeredAt + 10d → escalated=true
    App->>U: render HotlineFooter (10-day escalation; in-app only)
```

The above expands the plan §4.2 mermaid with three additions: the explicit `InterventionStateRepository` step (per ADR-0008 — Firestore-primary, SharedPreferences-mirror), the per-uid `notifications` settings read inside the CF, and the explicit "no_tokens" / "opted_out" / "rate_limited" branches that all log without sending.

## 5.5a — Copy parity + cooldown writes (Day 1 afternoon, flutter-engineer)

### Banner copy parity

The CLAUDE.md-locked sentence is one logical sentence:

```
"It's been a heavy week. Want to try a two-minute breathing exercise?"
```

`cheer_up_banner.dart:50` already concatenates correctly inside `Semantics(label: ...)`. The visual two-line layout (`titleSmall` + `bodyMedium`) is acceptable. Do NOT collapse the visual to a single `Text` — the two-line layout is part of the v1.0 visual baseline and changing it would invalidate the goldens qa-engineer adds Day 3.

**Required test (NEW):** `apps/mobile/test/features/garden/presentation/widgets/cheer_up_banner_test.dart` asserts:

```dart
final semantics = tester.getSemantics(find.byType(CheerUpBanner));
expect(
  semantics.label,
  startsWith("It's been a heavy week. Want to try a two-minute breathing exercise?"),
);
```

(`startsWith` rather than equality because the existing widget appends the reason caption to the label; `startsWith` keeps the locked sentence assertable without freezing the caption tail.)

### `InterventionStateRepository` — domain abstract (NEW)

Per ADR-0008, anchors move from SharedPreferences-only to Firestore-primary with a SharedPreferences offline mirror. The repository abstracts both:

**File:** `apps/mobile/lib/features/garden/domain/intervention_state_repository.dart` (NEW)

```dart
import 'package:core/core.dart';

/// Abstract contract for the cheer-up cooldown / escalation anchor store.
///
/// Two anchors are persisted per user:
///  * `lastTriggeredAt` — the most recent moment the detector reported
///    `triggered: true`. Drives the 48h cooldown gate.
///  * `firstTriggeredAt` — the start of the current escalation window.
///    Drives the 10-day in-app hotline-footer escalation. Cleared by the
///    detector lifecycle when 48h pass without a re-trigger.
///
/// Per ADR-0008 the implementation is Firestore-primary with a
/// SharedPreferences mirror that backs the offline-read path. Reads
/// prefer Firestore (synced cache); writes hit Firestore first then
/// mirror locally. The Cloud Function sees the Firestore copy.
abstract class InterventionStateRepository {
  /// Reads the persisted anchors. Result is `Ok(null)` when no anchor
  /// has ever been written. Never returns the SharedPreferences mirror
  /// when the Firestore read fails — instead the mirror is consulted as
  /// fallback inside the implementation, and the caller sees a single
  /// `Ok(value)` regardless.
  Future<Result<InterventionAnchors, InterventionStateFailure>> read();

  /// Idempotent write of `lastTriggeredAt`. Always overwrites.
  Future<Result<void, InterventionStateFailure>> writeLastTriggeredAt(
    DateTime now,
  );

  /// Writes `firstTriggeredAt` only if the persisted value is `null`.
  /// Idempotent across re-renders within the same trigger cycle.
  Future<Result<void, InterventionStateFailure>> writeFirstTriggeredAtIfNull(
    DateTime now,
  );

  /// Clears `firstTriggeredAt`. Called by the detector lifecycle when
  /// the cooldown window (48h) elapses without a re-trigger.
  Future<Result<void, InterventionStateFailure>> clearFirstTriggeredAt();
}

/// Pure-Dart anchor pair. No Flutter / Firebase imports.
class InterventionAnchors {
  const InterventionAnchors({this.lastTriggeredAt, this.firstTriggeredAt});
  final DateTime? lastTriggeredAt;
  final DateTime? firstTriggeredAt;
}

/// Failure modes for the anchor store. Sealed for exhaustive switch.
sealed class InterventionStateFailure extends Failure {
  const InterventionStateFailure({required super.message});
  const factory InterventionStateFailure.network() = _Network;
  const factory InterventionStateFailure.permission() = _Permission;
  const factory InterventionStateFailure.unknown(Object? cause) = _Unknown;
}

class _Network extends InterventionStateFailure {
  const _Network() : super(message: 'Network unavailable.');
}

class _Permission extends InterventionStateFailure {
  const _Permission() : super(message: 'Permission denied.');
}

class _Unknown extends InterventionStateFailure {
  const _Unknown(this.cause) : super(message: 'Something went wrong.');
  final Object? cause;
}
```

**Implementation:** `apps/mobile/lib/features/garden/data/intervention_state_repository_impl.dart` (NEW). Reads Firestore `users/{uid}/interventionState` (single doc, fields `lastTriggeredAt: timestamp`, `firstTriggeredAt: timestamp | null`). On Firestore failure during a read, falls back to the existing `InterventionStateStorage`. On every successful Firestore read, mirrors the values into `InterventionStateStorage` so the offline path stays warm. Writes hit Firestore first; on success, mirror locally. On Firestore failure during a write, still update the mirror so the local detector is correct, but return `Err(InterventionStateFailure.network())` — the caller decides whether to retry on next trigger.

**Provider rewire:** `apps/mobile/lib/features/garden/data/providers.dart` — replace direct `InterventionStateStorage` reads inside `interventionStateProvider` with the new `interventionStateRepositoryProvider`. The existing `InterventionStateStorage` class is kept verbatim and used as the mirror inside the impl — do not delete it.

### `CheerUpController` (NEW)

**File:** `apps/mobile/lib/features/garden/presentation/controllers/cheer_up_controller.dart` (NEW)

```dart
@riverpod
class CheerUpController extends _$CheerUpController {
  @override
  CheerUpUiState build() => const CheerUpUiState(
    bannerDismissed: false,
    onShownDispatched: false,
  );

  /// Called from the Garden screen via `addPostFrameCallback` exactly once
  /// per app launch when the upstream detector reports `triggered: true`.
  /// Idempotent: subsequent calls in the same lifecycle no-op via
  /// `state.onShownDispatched`.
  ///
  /// Writes happen in this order:
  ///   1. Repository writes (Firestore + mirror)
  ///   2. cheerUpEvents/{dayUtc}-{reason} create (idempotent)
  ///
  /// Step 2 is what the Cloud Function trigger fires on. If step 1 fails
  /// (network), step 2 still attempts (the CF only needs the event doc;
  /// the anchors live independently). If step 2 fails on
  /// `already-exists`, that is the idempotent path and we treat as ok.
  Future<void> onShown({required String reason}) async { ... }

  /// Session-scoped hide of the banner. Does NOT clear cooldown — the
  /// 48h gate is owned by `lastTriggeredAt`, not by this flag.
  void onDismissed() => state = state.copyWith(bannerDismissed: true);
}
```

The garden screen replaces `_bannerDismissed` (currently `garden_screen.dart:44`) with `ref.watch(cheerUpControllerProvider).bannerDismissed`. The `addPostFrameCallback` that calls `onShown(reason: ...)` is wired in the `_GardenView` constructor's `useEffect` equivalent or an explicit `ref.listen(interventionStateProvider, ...)` at the screen level.

### Files touched (5.5a)

- NEW `apps/mobile/lib/features/garden/domain/intervention_state_repository.dart`
- NEW `apps/mobile/lib/features/garden/data/intervention_state_repository_impl.dart`
- NEW `apps/mobile/lib/features/garden/presentation/controllers/cheer_up_controller.dart`
- EDIT `apps/mobile/lib/features/garden/data/providers.dart` (add repo provider; rewire `interventionStateProvider`)
- EDIT `apps/mobile/lib/features/garden/presentation/garden_screen.dart` (replace `_bannerDismissed`, add `addPostFrameCallback` invocation)

## 5.5b — `sendCheerUpPush` Cloud Function + tokens registry (Day 2, flutter-engineer + security-reviewer)

### Settings doc shape (per O11; canonical for the FCM path)

```
users/{uid}/settings/notifications  (single document, NOT a sub-collection)
{
  enabled: bool,
  tokens: [
    { token: string, platform: 'android' | 'web', updatedAt: timestamp },
    ...
  ]
}
```

`tokens[]` is bounded by the number of devices the user has signed in on. The CF iterates `tokens[]` and calls `sendEachForMulticast`. Stale tokens that come back with `messaging/registration-token-not-registered` are pruned post-send by a follow-up update (not a separate trigger — keeps the CF self-contained).

### Event doc — idempotent trigger (canonical)

```
users/{uid}/cheerUpEvents/{evtId}
{
  reason: '5_of_7_negative' | '3_consecutive_high_intensity',
  dayUtc: '2026-05-13',                        // YYYY-MM-DD, UTC
  createdAt: <server timestamp == request.time>,
  schemaV: 1,
}
```

**Doc id format:** `${dayUtc}-${reason}`, regex `/^\d{4}-\d{2}-\d{2}-(5_of_7_negative|3_consecutive_high_intensity)$/`. Two same-day re-evaluations collide on this id and the second `create` fails with `already-exists`, which the controller catches and treats as success. The CF therefore fires at most once per (uid, day, reason) combination — not just per uid per day, because a user could legitimately escalate from 5/7 to 3-consecutive on the same day. The per-uid 24h rate limit (next section) caps that to one push regardless.

### Firestore rule additions (canonical)

Append to `firebase/firestore.rules` inside `match /users/{uid} { ... }`:

```
match /cheerUpEvents/{evtId} {
  // Idempotent owner-create with id-format guard and server-stamped
  // createdAt. The id format MUST match `${dayUtc}-${reason}` so the CF
  // trigger can decode it without trusting payload fields.
  allow create: if isOwner(uid)
    && evtId.matches('^\\d{4}-\\d{2}-\\d{2}-(5_of_7_negative|3_consecutive_high_intensity)$')
    && request.resource.data.createdAt == request.time
    && request.resource.data.dayUtc is string
    && request.resource.data.dayUtc.matches('^\\d{4}-\\d{2}-\\d{2}$')
    && request.resource.data.reason in ['5_of_7_negative','3_consecutive_high_intensity']
    && request.resource.data.schemaV == 1
    && request.resource.data.diff({}.toMap()).affectedKeys()
       .hasOnly(['reason','dayUtc','createdAt','schemaV']);

  allow read: if isOwner(uid);
  allow update, delete: if false; // append-only audit log
}

match /interventionState/{docId} {
  // Single doc per user (docId = 'current'). Anchor pair, owner-rw,
  // immutable createdAt, validated timestamp shape.
  allow read: if isOwner(uid);
  allow create: if isOwner(uid)
    && docId == 'current'
    && request.resource.data.diff({}.toMap()).affectedKeys()
       .hasOnly(['lastTriggeredAt','firstTriggeredAt','schemaV'])
    && request.resource.data.schemaV == 1;
  allow update: if isOwner(uid)
    && docId == 'current'
    && request.resource.data.diff(resource.data).affectedKeys()
       .hasOnly(['lastTriggeredAt','firstTriggeredAt'])
    && (request.resource.data.lastTriggeredAt is timestamp
        || request.resource.data.lastTriggeredAt == null)
    && (request.resource.data.firstTriggeredAt is timestamp
        || request.resource.data.firstTriggeredAt == null);
  allow delete: if false;
}

match /settings/{settingId} {
  // settingId == 'notifications' for this brief; future settings docs
  // (e.g. 'preferences') reuse the same shape pattern.
  allow read: if isOwner(uid);
  allow create, update: if isOwner(uid)
    && settingId == 'notifications'
    && request.resource.data.diff(
         settingId == 'notifications'
           ? (resource == null ? {}.toMap() : resource.data)
           : {}.toMap()
       ).affectedKeys().hasOnly(['enabled','tokens'])
    && request.resource.data.enabled is bool
    && request.resource.data.tokens is list
    && request.resource.data.tokens.size() <= 10;
  allow delete: if false;
}
```

**Element-shape validation note:** Firestore rules cannot iterate list elements with arbitrary structure. The element-shape check `{ token, platform, updatedAt }` is enforced **in the client repository** (the only writer is `FcmTokenRepository`) and verified by an emulator test that asserts a malformed-element write is rejected by an additional defensive check: limiting `tokens.size() <= 10` in the rule (above) plus a server-side audit script that runs daily. If the security-reviewer judges 10 too generous as the only element-level guard, alternative is to model `tokens` as a sub-collection `users/{uid}/settings/notifications/tokens/{tokenId}` — flag this in the audit; default keeps the doc shape per O11.

### `sendCheerUpPush` Cloud Function — contract (canonical)

**File:** `functions/src/sendCheerUpPush.ts` (NEW)

```ts
// Trigger: Firestore onDocumentCreated('users/{uid}/cheerUpEvents/{evtId}')
// Region: 'asia-southeast1'
// Memory: '256MiB'
// Timeout: 30s
// Concurrency: default
// enforceAppCheck: not applicable (Firestore trigger, not callable)

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions';
import { consumeToken } from './rateLimit.js';

// Locked payload — no PII, no clinical language, no hotline copy.
const TITLE = 'A gentle check-in';
const BODY = "Noticing you've had a rough stretch. We're here.";
const CHANNEL_ID = 'cheer_up';

// Rate limit: at most ONE push per uid per 24h, regardless of trigger
// reason. Uses the existing `consumeToken` machinery from
// `rateLimit.ts`, parameterised per ADR-0007's pattern.
const RATE_LIMIT_WINDOW_MS = 86_400_000; // 24h
const RATE_LIMIT_MAX = 1;
const RATE_LIMIT_COLLECTION = 'rateLimits/cheerUp';

export const sendCheerUpPush = onDocumentCreated(
  {
    document: 'users/{uid}/cheerUpEvents/{evtId}',
    region: 'asia-southeast1',
    memory: '256MiB',
    timeoutSeconds: 30,
  },
  async (event) => {
    const uid = event.params.uid;
    const evtId = event.params.evtId;
    const requestId = event.id; // Firestore event id, log correlation

    const startMs = Date.now();
    const db = getFirestore();

    // 1. Read settings — opt-out short-circuit
    const settingsSnap = await db
      .doc(`users/${uid}/settings/notifications`)
      .get();
    const settings = settingsSnap.data() as
      | { enabled?: boolean; tokens?: Array<{ token: string; platform: string }> }
      | undefined;

    if (!settings || settings.enabled !== true) {
      logger.info({ event: 'cheerUpPush', requestId, uid, outcome: 'opted_out' });
      return;
    }
    const tokens = (settings.tokens ?? [])
      .map((t) => t.token)
      .filter((t): t is string => typeof t === 'string' && t.length > 0);
    if (tokens.length === 0) {
      logger.info({ event: 'cheerUpPush', requestId, uid, outcome: 'no_tokens' });
      return;
    }

    // 2. Rate limit — at most 1 push per uid per 24h
    const decision = await consumeToken(uid, Date.now(), {
      windowMs: RATE_LIMIT_WINDOW_MS,
      max: RATE_LIMIT_MAX,
      collection: RATE_LIMIT_COLLECTION,
    });
    if (!decision.allowed) {
      logger.info({
        event: 'cheerUpPush',
        requestId,
        uid,
        outcome: 'rate_limited',
        rateLimit: { remaining: 0, retryAfterSec: decision.retryAfterSec },
      });
      return;
    }

    // 3. Send multicast
    const messaging = getMessaging();
    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: { title: TITLE, body: BODY },
      android: { notification: { channelId: CHANNEL_ID, priority: 'high' } },
      // Web payload uses the default channel; FCM JS SDK ignores Android-only fields.
    });

    // 4. Prune dead tokens
    const dead: string[] = [];
    response.responses.forEach((r, i) => {
      if (
        !r.success &&
        r.error?.code === 'messaging/registration-token-not-registered'
      ) {
        dead.push(tokens[i]);
      }
    });
    if (dead.length > 0) {
      const survivors = (settings.tokens ?? []).filter(
        (t) => !dead.includes(t.token),
      );
      await settingsSnap.ref.update({ tokens: survivors });
    }

    // 5. Log — allowlist only
    logger.info({
      event: 'cheerUpPush',
      requestId,
      uid,
      outcome: 'sent',
      tokenCount: tokens.length,
      deliveredCount: response.successCount,
      failedCount: response.failureCount,
      prunedCount: dead.length,
      latencyTotalMs: Date.now() - startMs,
    });
  },
);
```

**Logger allowlist (PII fence):** `event, requestId, uid, outcome, tokenCount, deliveredCount, failedCount, prunedCount, latencyTotalMs, rateLimit.{remaining, retryAfterSec}, errorReason`. Forbidden: token strings, the `BODY` string, mood text, any field from the event doc beyond `reason` if a future log line needs it. The PII canary test asserts no captured log contains the token strings or the body.

**Index export:** `functions/src/index.ts` — add `export { sendCheerUpPush } from './sendCheerUpPush.js';`.

### Channel registration follow-up — R-001 from PR #23 audit

The same PR that adds `sendCheerUpPush.ts` MUST also register the Android notification channel `cheer_up` at app boot, or Android 8+ silently drops the push (FCM-attached notifications without a registered channel fall through). Add `flutter_local_notifications: ^17.x` to `pubspec.yaml` (already implied by the FCM path; pin to a version compatible with `firebase_messaging: ^15.x` per the FlutterFire matrix), and register the channel from `apps/mobile/lib/main.dart` or `apps/mobile/lib/app/bootstrap.dart` once `WidgetsFlutterBinding.ensureInitialized()` returns:

```dart
// MUST run before any FCM push can land. Without this on Android 8+
// the system drops cheer_up notifications silently.
final androidChannel = AndroidNotificationChannel(
  'cheer_up',
  'Cheer-up check-ins',
  description: 'Gentle reminders during heavier stretches.',
  importance: Importance.defaultImportance,
);
await FlutterLocalNotificationsPlugin()
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(androidChannel);
```

The Day-1 morning AndroidManifest bundle (per Sprint-5 plan §3) already adds `<meta-data android:name="com.google.firebase.messaging.default_notification_channel_id" android:value="cheer_up" />` so the FCM SDK's fallback channel matches. **Verification step for the security-reviewer:** confirm that the channel id in the CF payload (`channelId: 'cheer_up'`), the manifest meta-data, and the Dart `AndroidNotificationChannel` constructor all use the literal string `'cheer_up'`. A typo collapses the whole pipeline silently.

### Files touched (5.5b)

- NEW `apps/mobile/lib/features/notifications/domain/fcm_token_repository.dart`
- NEW `apps/mobile/lib/features/notifications/data/fcm_token_repository_impl.dart`
- NEW `apps/mobile/lib/features/notifications/data/providers.dart`
- NEW `apps/mobile/lib/features/notifications/presentation/notifications_bootstrapper.dart` (consumed in `app/router.dart` via `ref.listen`)
- NEW `functions/src/sendCheerUpPush.ts`
- NEW `functions/src/__tests__/sendCheerUpPush.test.ts`
- EDIT `functions/src/index.ts` (export)
- EDIT `firebase/firestore.rules` (cheerUpEvents, interventionState, settings — see canonical block above)
- EDIT `apps/mobile/pubspec.yaml` (`firebase_messaging`, `flutter_local_notifications`)
- EDIT `apps/mobile/lib/app/bootstrap.dart` or `main.dart` (channel registration; architect sign-off required for `main.dart` per CLAUDE.md "do-not-do list" — flag in PR description)
- EDIT `apps/mobile/android/app/src/main/AndroidManifest.xml` (already in Day-1 morning bundle)

### Tests to write (5.5b)

Server suite — `functions/src/__tests__/sendCheerUpPush.test.ts` (clone shape from `analyzePatterns.test.ts`):

1. **happy-path** — settings.enabled=true, 2 tokens, rate limit fresh → `sendEachForMulticast` called once with both tokens, payload matches `TITLE`/`BODY`, channelId is `cheer_up`, `outcome: 'sent'`, `deliveredCount: 2`.
2. **opted_out** — settings.enabled=false → no FCM call, no rate-limit consumption, log `outcome: 'opted_out'`.
3. **no_tokens** — settings.enabled=true, tokens=[] → no FCM call, no rate-limit consumption, log `outcome: 'no_tokens'`.
4. **rate_limited** — second invocation within 24h → no FCM call, log `outcome: 'rate_limited'`, `retryAfterSec` populated.
5. **dead-token pruning** — one of two tokens returns `registration-token-not-registered` → settings doc updated to drop that token, surviving tokens persist, `prunedCount: 1`.
6. **PII canary** — across all five cases, capture logger calls; assert no payload contains the token strings, no payload contains the literal `BODY` string, no payload contains the literal `TITLE` string.
7. **channel-id literal** — assert the messaging payload's `android.notification.channelId === 'cheer_up'`. Catches typos.

Coverage target: ≥90% on `sendCheerUpPush.ts`.

Widget tests — `apps/mobile/test/features/garden/presentation/widgets/cheer_up_banner_test.dart` (NEW):

8. **Semantics label parity** — concatenated `Semantics.label` starts with the locked sentence (per 5.5a).
9. **`onDismiss` callback fires** — tap "Not now" invokes the supplied callback; banner does not close itself.
10. **`Try it` opens overlay** — tap "Try it" pumps a `BreathingOverlay` into the dialog tree.

Integration test extension — `apps/mobile/integration_test/pattern_intervention_flow_test.dart` (rename + extend the S4 stub per Sprint-5 plan §7):

11. Seed 5-of-7 negative days into the fake mood repo, sign in, navigate Home, assert banner renders with locked sentence, assert `interventionStateRepositoryProvider` `read()` returns `lastTriggeredAt` non-null after first frame, assert `users/{uid}/cheerUpEvents/{dayUtc}-5_of_7_negative` is created (use Firestore emulator + `FakeFirebaseFirestore` for unit-side determinism).

## 5.5c — 10-day escalation footer (Day 2 afternoon, flutter-engineer)

The detector already writes `escalated: true` when `firstTriggeredAt + 10d ≤ now` (`pattern_detector.dart:103-110`). `garden_screen.dart:203-207` already conditionally renders `HotlineFooter` on `intervention.escalated`. With 5.5a populating `firstTriggeredAt`, no new wiring is needed — this is a **verification track**, not a build track.

**Required test (NEW):** `apps/mobile/test/features/garden/presentation/widgets/hotline_footer_visibility_test.dart` — pumps `interventionStateRepositoryProvider` overridden to return `firstTriggeredAt = now - 11.days`, drives the detector with currently-qualifying entries, and asserts `find.byType(HotlineFooter)` returns one widget. A second case pumps `firstTriggeredAt = now - 9.days` and asserts the footer is absent.

## Out-of-scope guardrails

- **No PII in payload.** `TITLE` and `BODY` are constants. The CF must not echo `reason`, mood text, the user's display name, the date, or any user-derived string into the FCM body. The locked title/body are the only strings the user sees on the lock screen.
- **No clinical language.** Re-audit `TITLE` and `BODY` against CLAUDE.md copy rules: no "depression", "anxiety disorder", "symptom", "diagnosis", no "improve", "boost", "overcome", no "you should". Current `BODY` ("Noticing you've had a rough stretch. We're here.") complies.
- **Hotline 1323 is in-app footer only.** It does not appear in the FCM body, the channel name, the channel description, or the manifest meta-data. The 10-day escalation surfaces in `HotlineFooter` only — a user who has notifications disabled still sees the footer in-app once they open the screen.
- **No streak shaming.** The CF logs `outcome: 'opted_out'` but never frames opt-out negatively to the user; there is no "you missed your check-in" UI.
- **No `data:` payload abuse.** The CF sends a `notification` payload (locked title/body) and an `android.notification.channelId`. It does NOT send a `data` payload that the app could use to deep-link into a screen — that path is open for v1.6 and would need a separate ADR.

## Acceptance criteria

The feature is complete when:

- [ ] `cd functions && pnpm test` — all 7 server cases green; ≥90% coverage on `sendCheerUpPush.ts`; PII canary passes.
- [ ] `cd apps/mobile && flutter test` — banner Semantics label test green; widget tests for "Not now" and "Try it" green; hotline footer visibility test green; existing suite still green.
- [ ] `cd firebase/test && pnpm test` — new rules cases for `cheerUpEvents` (regex enforcement, immutable createdAt, append-only), `interventionState` (immutable schemaV, allowed key set), and `settings/notifications` (key-set guard, list-size cap).
- [ ] `flutter test integration_test/pattern_intervention_flow_test.dart -d android` AND `-d chrome` — both green.
- [ ] Manual: seed Som's 5-of-7 fixture; banner renders with locked sentence; FCM arrives on Android emulator within 30s of the event-doc write (verify via Firebase Console → Cloud Messaging → test send by uid as a sanity check); tap "Try it" → breathing overlay; cooldown gate suppresses re-trigger within 48h on next mood-log; seed `firstTriggeredAt = now - 11d` → hotline footer renders.
- [ ] Channel id `cheer_up` is consistent across CF payload, manifest meta-data, and `AndroidNotificationChannel` constructor (security-reviewer verification step).
- [ ] No log payload across the test suite contains the token strings, the locked title, or the locked body.
- [ ] Non-author approver merges (Enterprise R3 — flutter-engineer cannot self-approve).

## Open questions

- **OQ-A (token list shape)** — flag for security-reviewer: list-element validation in Firestore rules can only check `tokens.size()`. If the audit finds 10-element + client-side validation insufficient, the alternative is `users/{uid}/settings/notifications/tokens/{tokenId}` as a sub-collection. Default: ship the doc-shape per O11; revisit in v1.6 if the audit pushes back.
- **OQ-B (Web FCM permission UX)** — Web requires an explicit `Notification.requestPermission()` from a user gesture. The settings tile (WBS 6.3, separate brief) handles this; this brief assumes the tile exists by Day 2. If WBS 6.3 slips, flutter-engineer ships the CF + rules and lands the Web permission prompt in a follow-up PR within S5.
