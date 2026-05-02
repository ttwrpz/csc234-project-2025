# Runbook — Feature Flag Rollback

**Owner:** Theerawat (orchestrator) — escalates to Kraiwich for app-side debug.
**Audience:** anyone with Firebase Console "Editor" on the MoodBloom project.
**Last updated:** 2026-05-11.

This runbook covers two scenarios:

1. **Demo kill-switch rehearsal** — flipping `ai_pattern_analysis_enabled` mid-demo to prove the Pattern Insights card hides gracefully. Required Enterprise Term Assignment evidence per the Sprint 4 acceptance bar.
2. **Production incident rollback** — if Gemini misbehaves post-launch, flipping the same flag to `false` while we investigate.

Both flows use the same Remote Config key. They differ only in the **minimum fetch interval** the client honours (see §"Demo prep" below).

## Flags in scope

| Key | Default | Hides what when `false` |
|---|---|---|
| `ai_pattern_analysis_enabled` | `true` | The Pattern Insights card on the Analytics screen. Mood logging + history + chart are unaffected. |
| `gemini_detection_enabled` | `true` | The AI suggestion pill on the Log Mood screen. Manual mood selection still works. (S3 — listed for completeness; out of scope for this runbook.) |

Both keys are registered as defaults in `apps/mobile/lib/main.dart` (`rc.setDefaults(...)`). The defaults are baked into the build so a never-fetched client still sees a working app.

## Demo prep — lower the minimum fetch interval (v1.0 only — RESTORED)

> **Status as of v1.0.1:** the `minimumFetchInterval` is back to **60 minutes**. Production clients pick up server-side flag flips within an hour. The 60-second window described below applies ONLY to the original v1.0 demo build that has since been superseded.

For the original v1.0 demo, `FirebaseRemoteConfig.minimumFetchInterval` was lowered to **60 seconds** (per kickoff Open Question O-3) so the kill-switch rehearsal could complete within the kickoff acceptance bar. That interval was restored to 60 minutes in v1.0.1 to avoid flooding Remote Config with fetch requests in production. The current code:

```dart
// apps/mobile/lib/main.dart (v1.0.1 — restored)
await rc.setConfigSettings(
  RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: const Duration(minutes: 60),
  ),
);
```

**If you ever need to re-stage the demo on a fresh build** (e.g. for the v1.x retrospective), temporarily flip `Duration(minutes: 60)` → `Duration(seconds: 60)` on a throwaway demo branch — never on `main`.

## Demo kill-switch — step-by-step

1. **Confirm baseline.** Open the app on the demo device. Navigate to the **Insights** tab. Verify a Pattern Insights card renders with at least one row.
2. **Open Firebase Console.** `Run > Remote Config` for the MoodBloom project. Find the `ai_pattern_analysis_enabled` parameter.
3. **Flip the flag.** Click the parameter, set "Default value" from `true` to `false`. Click **Save**.
4. **Publish.** Click the **Publish changes** banner at the top of the page. Confirm in the modal. The flip is live now.
5. **Wait ≤ 60 seconds.** The client's next Remote Config fetch (triggered by the existing `unawaited(rc.fetchAndActivate())` at startup OR by re-entering the Insights tab) will activate the new value. The Pattern Insights card disappears.
6. **Verify mood logging is unaffected.** Tap the **Log** tab → log a quick mood → confirm it lands in the History tab. No clinical-language errors. No Crashlytics reports.
7. **Restore.** Flip `ai_pattern_analysis_enabled` back to `true` in Firebase Console → **Publish**. Wait ≤ 60 seconds → the card returns.

## Production incident rollback

Same procedure as steps 2–4 above. **Do NOT** lower `minimumFetchInterval` — production clients on v1.0.1+ see the change within ≤ 60 minutes (60-min default), which is the documented SLO.

After flipping the flag, file a Crashlytics issue + post in `#mobile-incidents` with:
- the flag name
- the time of the flip
- the user-facing impact (e.g. "Insights card hidden globally; mood logging unaffected")
- a link to the Gemini Cloud Function logs that prompted the action

## ~~Restoring the 60-minute interval (v1.0.1)~~ — DONE

The 60-minute `minimumFetchInterval` was restored in the v1.0.1 patch at `apps/mobile/lib/main.dart`. No further action required. Section retained for historical reference; remove on the next runbook revision.

## Failure modes

- **Flip published, card still visible after 60 seconds.** Check that the demo device has network connectivity. The client will not fetch over a captive portal. Toggle airplane mode off → on → off as a forced refresh.
- **Card disappears, mood logging breaks.** Not possible by design — the flag only gates the Insights card render path. If this happens, file a Crashlytics issue and revert the flag immediately.
- **Wrong flag flipped.** `gemini_detection_enabled` hides the AI suggestion pill on Log Mood — different surface, different blast radius. Restore via the same Console UI.
