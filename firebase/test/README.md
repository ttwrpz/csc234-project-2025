# Firestore + Storage Rules Test Harness (WBS 2.3)

Emulator-driven tests for `firebase/firestore.rules` and `firebase/storage.rules`.
Implements the full 15-case audit table from the Sprint 3 handoff brief
(`.claude/briefs/sprint-3/security-rules.md`).

## Run locally

```bash
# from repo root
firebase emulators:exec \
  --only firestore,storage,auth \
  --project moodbloom-rules-test \
  "cd firebase/test && npm test"
```

Or, if you already have the emulators running on the canonical ports
(8080 firestore, 9099 auth, 9199 storage), run only the jest suite:

```bash
cd firebase/test && npm test
```

## Toolchain

Verified green against:

| Tool | Version |
|---|---|
| firebase-tools | 15.15.0 |
| Node.js | 20.x and 24.x |
| Java (firestore emulator) | 17 LTS or 21 LTS |
| @firebase/rules-unit-testing | ^3.0.4 |
| firebase (client SDK) | ^10.12.2 |
| jest / ts-jest | ^29 |

## Notes

- `jest.config.js` sets `maxWorkers: 1` so a single suite owns the emulator
  ports (8080/9199/9099) at a time. Do not raise this; rules tests are not
  isolated by project per worker, only by `clearFirestore()` between cases.
- `beforeEach` calls `testEnv.clearFirestore()` so cases never pollute each
  other. Storage objects auto-discard with the test env.
- `withSecurityRulesDisabled` is used to seed pre-existing fixtures (e.g. an
  entry created 25h ago for the lock-window cases) bypassing rules - exactly
  what the API is designed for.
- Lock-window cases use `firebase.firestore.Timestamp.fromMillis(...)` to
  control `createdAt`; rules compare against `request.time` (server clock),
  which the emulator sets to the actual current time on each RPC.
- A benign `NullPointerException` may be logged from
  `com.google.firebase.rules.tools.local.server.Server` on emulator shutdown
  - this is upstream and unrelated to test results.

## Adding a case

1. Append a new `it(...)` to the appropriate `describe` block.
2. Use `assertSucceeds` / `assertFails` from `@firebase/rules-unit-testing`.
3. If the case relies on a pre-existing document, seed it via the
   `seedMoodEntry` helper or `testEnv.withSecurityRulesDisabled(...)` directly.
4. Update the case-count badge in `.claude/briefs/sprint-3/security-rules.md`
   if the case count changes.
