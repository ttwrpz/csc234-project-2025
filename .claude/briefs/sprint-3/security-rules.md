# Handoff Brief - Firestore Security Rules (WBS 2.3)

**Sprint:** 3 (Day 1 evening → Day 2 afternoon)
**Owner:** flutter-engineer
**Mandatory gate:** security-reviewer agent must sign off before merge (CLAUDE.md "do-not-do list" - `firebase/firestore.rules` requires sign-off)
**WBS ID:** 2.3 (Firestore security rules with `diff().affectedKeys()` + per-user RBAC)

## Goal

Replace the Sprint 2 placeholder `firebase/firestore.rules` (per-user collection-level allow) with field-validated, time-bounded rules that match the domain invariants:

1. **Per-user RBAC** - only `request.auth.uid == uid` reads/writes under `users/{uid}/**`.
2. **Server-timestamped `createdAt`** on create; immutable on update.
3. **24h immutability** - `request.time - resource.data.createdAt < 86_400_000ms` for update/delete.
4. **Field-level allowlist** on update via `diff().affectedKeys().hasOnly([...])`.
5. **Schema validation** at the rules layer for `mood`, `intensity`, `text` length.
6. **Storage rules** allow user-scoped media uploads to `users/{uid}/media/**`; deny everything else; size cap 25MB; contentType allowlist images + videos.
7. **`rateLimits/{uid}`** collection - admin-SDK only; clients deny.
8. **`users/{uid}/insights/{id}`** - read-only for the user; write-only via Cloud Function admin SDK (S4 pattern analysis).

## Canonical rules (`firebase/firestore.rules`)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isOwner(uid) {
      return request.auth != null && request.auth.uid == uid;
    }

    match /users/{uid} {
      allow read, write: if isOwner(uid);

      match /moods/{moodId} {
        allow create: if isOwner(uid)
          && request.resource.data.createdAt == request.time
          && request.resource.data.intensity is int
          && request.resource.data.intensity >= 1
          && request.resource.data.intensity <= 5
          && request.resource.data.text is string
          && request.resource.data.text.size() <= 500
          && request.resource.data.mood in ['happy','calm','okay','sad','angry','anxious'];

        allow read: if isOwner(uid);

        allow update: if isOwner(uid)
          && request.time.toMillis() - resource.data.createdAt.toMillis() < 86400000
          && request.resource.data.createdAt == resource.data.createdAt
          && request.resource.data.diff(resource.data).affectedKeys()
             .hasOnly(['mood','intensity','text','mediaRefs','updatedAt'])
          && request.resource.data.intensity is int
          && request.resource.data.intensity >= 1
          && request.resource.data.intensity <= 5
          && request.resource.data.text.size() <= 500
          && request.resource.data.mood in ['happy','calm','okay','sad','angry','anxious'];

        allow delete: if isOwner(uid)
          && request.time.toMillis() - resource.data.createdAt.toMillis() < 86400000;
      }

      match /insights/{insightId} {
        allow read: if isOwner(uid);
        allow create, update, delete: if false;  // Cloud Function admin SDK only - S4
      }
    }

    match /rateLimits/{uid} {
      allow read, write: if false;  // admin SDK only
    }
  }
}
```

## Canonical rules (`firebase/storage.rules`)

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{uid}/media/{path=**} {
      allow read, write: if request.auth != null
                         && request.auth.uid == uid
                         && request.resource.size < 25 * 1024 * 1024
                         && request.resource.contentType.matches('image/.*|video/.*');
    }
    match /{path=**} {
      allow read, write: if false;
    }
  }
}
```

## Emulator test harness

Create `firebase/test/firestore_rules.test.ts` (jest + `@firebase/rules-unit-testing`). Bootstrap a single test project per file with `initializeTestEnvironment`. Use `assertSucceeds` / `assertFails` helpers. Tests must pass under the `firebase emulators:exec` workflow that runs in CI (`.github/workflows/ci.yml` job to be added at D1.5).

### Test cases (≥10 - at least 14 are listed)

| # | Case | Expected |
|---|---|---|
| 1 | `users/userA/moods` write by `userB` | DENY |
| 2 | Create with `createdAt != request.time` | DENY |
| 3 | Create with `intensity = 0` | DENY |
| 4 | Create with `intensity = 6` | DENY |
| 5 | Create with `text` of 501 chars | DENY |
| 6 | Create with `mood = 'melancholy'` (not in enum) | DENY |
| 7 | Update of entry with `createdAt = now - 25h` | DENY |
| 8 | Update of entry with `createdAt = now - 23h` | ALLOW |
| 9 | Update mutating `createdAt` | DENY |
| 10 | Update mutating `userId` (not in `affectedKeys` whitelist) | DENY |
| 11 | Delete of entry with `createdAt = now - 25h` | DENY |
| 12 | Read other user's `rateLimits/{otherUid}` | DENY |
| 13 | Storage upload to `users/{otherUid}/media/...` | DENY |
| 14 | Storage upload of 30MB file | DENY |
| 15 | Storage upload of `application/pdf` | DENY |

## Sequencing

| When | Action | Owner |
|---|---|---|
| Day 1 evening | Draft rules file + emulator harness scaffold | flutter-engineer |
| Day 2 morning | Complete the 14+ test cases; all pass locally | flutter-engineer |
| Day 2 afternoon | Open PR; tag `security-reviewer`; address findings | flutter-engineer ↔ security-reviewer |
| Day 2 EOD | Merge after security-reviewer signs off in the PR | flutter-engineer |

## Security-reviewer audit checklist

- [ ] No public-read exposure on any path.
- [ ] No write path that bypasses `request.auth.uid == uid`.
- [ ] `createdAt` cannot be backdated on create (the `== request.time` clause holds).
- [ ] `createdAt` cannot be modified on update (the equality clause holds).
- [ ] 24h immutability uses `request.time` (server time, not client `Timestamp.now()`).
- [ ] `affectedKeys().hasOnly(...)` whitelists only `mood, intensity, text, mediaRefs, updatedAt` - not `userId`, not `createdAt`, not unknown future fields.
- [ ] `mood in [...]` covers exactly the six MoodType values.
- [ ] `rateLimits/{uid}` is admin-SDK-only (`if false` for client read+write).
- [ ] `insights/{id}` is read-only for the user (S4 Cloud Function writes).
- [ ] Storage size cap and contentType allowlist hold under typed binary uploads.
- [ ] Risk register entry created in the PR description.

## Files

Modify:
- `firebase/firestore.rules`
- `firebase/storage.rules`

Create:
- `firebase/test/firestore_rules.test.ts`
- `firebase/test/package.json` (jest + `@firebase/rules-unit-testing`)
- `firebase/test/tsconfig.json`
- `firebase.json` - extend `emulators` block with `firestore` (port 8080) and `auth` (port 9099) emulator config

## What NOT to do

- Do not change `users/{uid}` parent-collection rules to be looser than feature subcollections.
- Do not add a "convenience" `allow read: if true` for any path. Defaults are deny; rules are explicit allow.
- Do not weaken the 24h check to client-supplied `updatedAt` (defeats the immutability invariant).
- Do not deploy these rules to production from a developer machine. Deploy goes through CI on tag, never `firebase deploy` from a laptop (also enforced by `.claude/hooks/settings.json` deny entry for `firebase deploy`).

## References

- ADR-0004 §"24h immutability - three-layer enforcement" - these rules are layer 4 of the guard.
- CLAUDE.md "Firestore data model" + "Security rules (non-negotiable)".
- `apps/mobile/lib/features/mood/domain/entities/mood_type.dart` - canonical six-mood enum used in the `mood in [...]` clause.
