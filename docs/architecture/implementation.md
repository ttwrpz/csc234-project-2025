# MoodBloom — Implementation Architecture

This document grounds the conceptual layers in concrete file paths. The `mood/` feature is shown end-to-end as the canonical reference; every other feature follows the same pattern. All paths are rooted at the repository root and assume the monorepo layout decided in [ADR-0001](../adr/0001-repo-structure-and-clean-architecture.md).

## The `mood/` feature, expanded

```mermaid
flowchart TD
    subgraph Pres["apps/mobile/lib/features/mood/presentation/"]
        Screen[log_mood_screen.dart]
        Ctrl[controllers/log_mood_controller.dart<br/>@riverpod LogMoodController]
        Slider[widgets/intensity_slider.dart]
    end

    subgraph Domain["apps/mobile/lib/features/mood/domain/ (zero Flutter/Firebase imports)"]
        Entity[entities/mood_entry.dart<br/>@freezed MoodEntry]
        UC[usecases/save_mood_entry.dart<br/>SaveMoodEntryUseCase]
        Repo[mood_repository.dart<br/>abstract MoodRepository]
    end

    subgraph Data["apps/mobile/lib/features/mood/data/"]
        Impl[mood_repository_impl.dart<br/>implements MoodRepository]
        DS[datasources/mood_firestore_datasource.dart]
        DTO[dtos/mood_entry_dto.dart<br/>fromJson/toJson]
        Map[mappers/mood_entry_mapper.dart]
    end

    Firestore[(Cloud Firestore<br/>users/&#123;uid&#125;/moods/&#123;moodId&#125;)]
    Core[packages/core/<br/>Result&lt;T, Failure&gt;, Logger]

    Screen --> Ctrl
    Slider --> Ctrl
    Ctrl -->|ref.read saveMoodEntryUseCaseProvider| UC
    UC -->|repo.save entry| Repo
    Impl -.->|implements| Repo
    Impl --> DS
    DS --> Firestore
    Impl --> Map
    Map --> DTO
    Map --> Entity
    UC --> Entity
    Ctrl --> Core
    Impl --> Core

    classDef domain fill:#fef3c7,stroke:#b45309,stroke-width:2px
    classDef pres fill:#dbeafe,stroke:#1d4ed8
    classDef data fill:#dcfce7,stroke:#15803d
    classDef ext fill:#f3f4f6,stroke:#6b7280,stroke-dasharray: 4 4
    class Domain domain
    class Pres pres
    class Data data
    class Firestore,Core ext
```

## CLAUDE.md code samples → file paths

The Dart snippets in `CLAUDE.md` § "Dart style — specific patterns we enforce" map to these files in the `mood/` feature:

| CLAUDE.md snippet | Target file path |
|---|---|
| `@freezed class MoodEntry` | `apps/mobile/lib/features/mood/domain/entities/mood_entry.dart` |
| Generated `MoodEntry._$MoodEntryFromJson` | `apps/mobile/lib/features/mood/domain/entities/mood_entry.freezed.dart` (generated; do not hand-edit) and `mood_entry.g.dart` (generated) |
| `@riverpod class LogMoodController` | `apps/mobile/lib/features/mood/presentation/controllers/log_mood_controller.dart` |
| Generated `_$LogMoodController` | `apps/mobile/lib/features/mood/presentation/controllers/log_mood_controller.g.dart` (generated) |
| `abstract class MoodRepository` | `apps/mobile/lib/features/mood/domain/mood_repository.dart` |
| Concrete `MoodRepositoryImpl` | `apps/mobile/lib/features/mood/data/mood_repository_impl.dart` |
| `MoodDraft` (controller state) | `apps/mobile/lib/features/mood/domain/entities/mood_draft.dart` |
| `SaveMoodEntryUseCase` | `apps/mobile/lib/features/mood/domain/usecases/save_mood_entry.dart` |
| `Result<T, Failure>` | `packages/core/lib/src/result.dart` |
| `Failure` sealed class | `packages/core/lib/src/failure.dart` |
| `Logger` | `packages/core/lib/src/logger.dart` |

## Riverpod provider wiring

Providers live next to their consumers, not in a global file:

| Provider | File |
|---|---|
| `moodRepositoryProvider` (returns `MoodRepository`) | `apps/mobile/lib/features/mood/data/providers.dart` |
| `saveMoodEntryUseCaseProvider` | `apps/mobile/lib/features/mood/domain/usecases/save_mood_entry.dart` (co-located with use case) |
| `firestoreProvider` (root `FirebaseFirestore` instance) | `apps/mobile/lib/app/providers.dart` |
| `firebaseAuthProvider` | `apps/mobile/lib/app/providers.dart` |

In tests, `ProviderContainer` overrides `moodRepositoryProvider` with a fake that returns canned `Result` values, exercising controllers without Firestore.

## Firestore document shape vs. domain entity

The DTO at `apps/mobile/lib/features/mood/data/dtos/mood_entry_dto.dart` mirrors the on-wire schema from `CLAUDE.md` § "Firestore data model": `{ mood, intensity, text, createdAt, updatedAt, mediaRefs[] }` at `users/{uid}/moods/{moodId}`. The mapper at `mappers/mood_entry_mapper.dart` converts DTO ↔ `MoodEntry` entity. The entity carries the `int intensity` field (1..5, the pivot-feature invariant) and the use case enforces the range; the Firestore security rules (Sprint 3) enforce it again server-side.

## Other features

`auth/`, `garden/`, `analytics/`, `history/`, `settings/`, `onboarding/` follow the identical triad. Sprint 2 scaffolds empty `presentation/`, `domain/`, `data/` folders for each (with `.gitkeep`); Sprints 3–5 fill them.
