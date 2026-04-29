import 'package:core/core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/data/providers.dart';
import '../../data/providers.dart';
import '../../domain/entities/mood_draft.dart';
import '../../domain/entities/mood_entry.dart';
import '../../domain/entities/mood_media.dart';
import '../../domain/entities/mood_type.dart';
import '../../domain/mood_failure.dart';
import 'log_mood_submission_controller.dart';

part 'log_mood_controller.g.dart';

/// Controller for `LogMoodScreen`. State is [MoodDraft] directly — it is the
/// canonical in-progress entry shape and does not need a wrapper.
///
/// Transient submission state (`isSubmitting`, `errorMessage`) lives on the
/// sibling [LogMoodSubmissionController]. Navigation on success is performed
/// by the screen, not this controller — keeps the controller free of
/// `BuildContext` and `package:go_router` imports.
@riverpod
class LogMoodController extends _$LogMoodController {
  @override
  MoodDraft build() => MoodDraft.empty();

  void pickMood(MoodType mood) => state = state.copyWith(mood: mood);

  void setIntensity(int value) => state = state.copyWith(intensity: value);

  void setText(String text) => state = state.copyWith(text: text);

  /// Append a single picked attachment. Order matters — the strip renders
  /// pickedMedia in insertion order and uploads happen in the same order.
  void addMedia(MoodMedia media) {
    state = state.copyWith(pickedMedia: [...state.pickedMedia, media]);
  }

  /// Append several picked attachments at once (typical from
  /// `pickMultiImage`).
  void addAllMedia(List<MoodMedia> items) {
    if (items.isEmpty) return;
    state = state.copyWith(pickedMedia: [...state.pickedMedia, ...items]);
  }

  /// Remove the attachment at [index]. Out-of-range indices are silently
  /// ignored — defense in depth against double-tap on the remove affordance.
  void removeMedia(int index) {
    if (index < 0 || index >= state.pickedMedia.length) return;
    final next = [...state.pickedMedia]..removeAt(index);
    state = state.copyWith(pickedMedia: next);
  }

  /// Validates the draft, uploads any picked media sequentially, and forwards
  /// the populated entry to the save use case. Returns the saved [MoodEntry]
  /// on success or `null` on failure.
  ///
  /// Upload sequencing — see WBS 3.3 brief: pick-time uploads are wasteful if
  /// the user backs out, so we upload at save time. Sequential (not parallel)
  /// keeps low-bandwidth users from saturating their pipe and simplifies
  /// error handling — first failure aborts and the entry is NOT half-written.
  ///
  /// If uploads succeed but the Firestore save fails, the uploaded blobs are
  /// orphaned at `users/{uid}/media/{moodId}/...`. A janitor cron in S4
  /// reaps these — see [MoodMediaRepositoryImpl] doc.
  Future<MoodEntry?> save() async {
    final submission = ref.read(logMoodSubmissionControllerProvider.notifier);
    final user = ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null) {
      // Defense in depth — the router already prevents reaching this screen
      // unauthenticated.
      submission.fail('You need to be signed in.');
      return null;
    }
    submission.begin();

    // Upload picked media (if any) before persisting the entry. We use a
    // pseudo-id "draft" for the path — Firestore allocates the real id on
    // save, but uploads need a stable folder up front. Storage rules permit
    // any path under `users/{uid}/media/**`, so this is safe.
    final mediaRefs = <String>[];
    if (state.pickedMedia.isNotEmpty) {
      final uploader = ref.read(uploadMoodMediaUseCaseProvider);
      const moodFolder = 'draft';
      for (final media in state.pickedMedia) {
        final result = await uploader(
          userId: user.uid,
          moodId: moodFolder,
          media: media,
        );
        switch (result) {
          case Ok(:final value):
            mediaRefs.add(value);
          case Err(:final failure):
            submission.fail(failure.message);
            return null;
        }
      }
    }

    final usecase = ref.read(saveMoodEntryUseCaseProvider);
    final draftWithRefs = state.copyWith(
      mediaRefs: [...state.mediaRefs, ...mediaRefs],
    );
    final result = await usecase(userId: user.uid, draft: draftWithRefs);
    return switch (result) {
      Ok(:final value) => _onSaveOk(submission, value),
      Err(:final failure) => _onSaveErr(submission, failure),
    };
  }

  MoodEntry _onSaveOk(
    LogMoodSubmissionController submission,
    MoodEntry entry,
  ) {
    submission.succeed();
    state = MoodDraft.empty();
    return entry;
  }

  Null _onSaveErr(
    LogMoodSubmissionController submission,
    MoodFailure failure,
  ) {
    submission.fail(failure.message);
    return null;
  }
}
