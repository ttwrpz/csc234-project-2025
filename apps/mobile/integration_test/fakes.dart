import 'dart:async';

import 'package:core/core.dart';
import 'package:drift/native.dart';
import 'package:moodbloom/features/auth/domain/auth_failure.dart';
import 'package:moodbloom/features/auth/domain/auth_repository.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/mood/data/datasources/mood_firestore_datasource.dart';
import 'package:moodbloom/features/mood/data/dtos/mood_entry_dto.dart';
import 'package:moodbloom/features/mood/data/local/mood_database.dart';
import 'package:moodbloom/features/mood/data/mappers/mood_entry_mapper.dart';
import 'package:moodbloom/features/mood/data/sync/mood_sync_manager.dart';
import 'package:moodbloom/features/mood/domain/entities/mood_entry.dart';
import 'package:moodbloom/features/mood/domain/mood_failure.dart';
import 'package:moodbloom/features/mood/domain/mood_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integration-test stand-in for [AuthRepository]. Driven by tests via
/// [setUser]; emits each new value on the auth-state stream so the
/// router's `refreshListenable` picks up the transition. Captures every
/// `signInWithEmail` call so tests can assert on credentials.
///
/// The S5 expansion (this file) replaces the per-file `_IntegrationAuthRepository`
/// in `auth_flow_test.dart` so other flows (mood-log, AI-override,
/// pattern-intervention) can reuse it without the copy-paste.
class IntegrationAuthRepository implements AuthRepository {
  IntegrationAuthRepository({AppUser? initialUser}) : _user = initialUser {
    // Seed the broadcast stream with the initial value so the very
    // first listener (router) receives a synchronous emission.
    _controller.add(_user);
  }

  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();
  AppUser? _user;

  /// Captured `signInWithEmail` calls, in order. Tests assert against this.
  final List<({String email, String password})> signInCalls = [];

  /// If non-null, [signInWithEmail] returns this and does NOT update the
  /// auth state. Tests use it to drive the bad-creds path.
  Result<AppUser, AuthFailure>? nextSignInResult;

  /// Drive a sign-in transition manually (used by tests that bypass the UI).
  /// Not the same as calling [signInWithEmail] — does not record a call.
  void setUser(AppUser? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> watchAuthState() => _controller.stream;

  @override
  Future<Result<AppUser, AuthFailure>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInCalls.add((email: email, password: password));
    final preset = nextSignInResult;
    nextSignInResult = null;
    if (preset != null) {
      // Bad-creds (or other) drive: do NOT update the user; the screen
      // should surface the failure message.
      return preset;
    }
    final user = AppUser(uid: 'u-${signInCalls.length}', email: email);
    setUser(user);
    return Ok(user);
  }

  @override
  Future<Result<AppUser, AuthFailure>> registerWithEmail({
    required String email,
    required String password,
  }) async => const Err(AuthFailure.unknown(null));

  @override
  Future<Result<AppUser, AuthFailure>> signInWithGoogle() async =>
      const Err(AuthFailure.unknown(null));

  @override
  Future<Result<void, AuthFailure>> signOut() async {
    setUser(null);
    return const Ok(null);
  }

  Future<void> dispose() async => _controller.close();
}

/// Integration-test [MoodRepository]. Backed by a per-uid in-memory
/// store with a broadcast stream so saves are reflected in
/// `myMoodsStreamProvider` without a manual refresh.
///
/// Mirrors the unit-test `FakeMoodRepository` shape but drives the
/// stream live (the unit-test fake yields a fixed sequence) — required
/// here because the History screen subscribes to `watchAll(...)` and
/// must observe a save made by the Log screen.
class IntegrationMoodRepository implements MoodRepository {
  final Map<String, List<MoodEntry>> _store = {};
  final StreamController<List<MoodEntry>> _stream =
      StreamController<List<MoodEntry>>.broadcast();

  /// Captures every entry passed to [save] for assertion.
  final List<MoodEntry> saveCalls = [];

  /// If non-null, [save] returns this instead of the auto-allocated id.
  /// Useful for forcing failure paths.
  Result<MoodEntry, MoodFailure>? saveResult;

  String? _watchUserId;

  /// Pre-seed entries for a user. Used by pattern-intervention tests
  /// that need a populated history.
  void seed(String userId, List<MoodEntry> entries) {
    _store[userId] = List<MoodEntry>.from(entries);
    if (_watchUserId == userId) _emit(userId);
  }

  void _emit(String userId) {
    final entries = _store[userId] ?? const <MoodEntry>[];
    // Newest-first; this is what the production repo guarantees.
    final sorted = [...entries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _stream.add(sorted);
  }

  @override
  Stream<List<MoodEntry>> watchAll({required String userId}) async* {
    _watchUserId = userId;
    // Synchronous initial emission so the History list renders without
    // a microtask delay.
    final initial = _store[userId] ?? const <MoodEntry>[];
    yield [...initial]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield* _stream.stream;
  }

  @override
  Future<Result<MoodEntry, MoodFailure>> findById({
    required String userId,
    required String id,
  }) async {
    final entries = _store[userId] ?? const <MoodEntry>[];
    for (final e in entries) {
      if (e.id == id) return Ok(e);
    }
    return Err(MoodFailure.notFound(id));
  }

  @override
  Future<Result<MoodEntry, MoodFailure>> save(MoodEntry entry) async {
    saveCalls.add(entry);
    final preset = saveResult;
    if (preset != null) {
      saveResult = null;
      return preset;
    }
    // Allocate a stable id like the production datasource would.
    final allocated = entry.copyWith(
      id: entry.id.isEmpty ? 'srv-${saveCalls.length}' : entry.id,
    );
    final list = _store.putIfAbsent(entry.userId, () => <MoodEntry>[]);
    list.add(allocated);
    _emit(entry.userId);
    return Ok(allocated);
  }

  @override
  Future<Result<MoodEntry, MoodFailure>> update(MoodEntry entry) async {
    final list = _store[entry.userId] ?? const <MoodEntry>[];
    final idx = list.indexWhere((e) => e.id == entry.id);
    if (idx < 0) return Err(MoodFailure.notFound(entry.id));
    final next = [...list]..[idx] = entry;
    _store[entry.userId] = next;
    _emit(entry.userId);
    return Ok(entry);
  }

  @override
  Future<Result<void, MoodFailure>> delete({
    required String userId,
    required String id,
  }) async {
    final list = _store[userId] ?? const <MoodEntry>[];
    _store[userId] = [...list.where((e) => e.id != id)];
    _emit(userId);
    return const Ok(null);
  }

  Future<void> dispose() async => _stream.close();
}

/// No-op Firestore datasource used solely to satisfy [FakeSyncManager]'s
/// constructor. Bootstrap and shutdown are intercepted, so this stub is
/// never actually invoked during a passing integration test.
class _NoopFirestoreDatasource implements MoodFirestoreDatasource {
  @override
  Stream<List<MoodEntryDto>> watchAll(String userId) =>
      const Stream<List<MoodEntryDto>>.empty();

  @override
  Future<MoodEntryDto?> findById({
    required String userId,
    required String id,
  }) async => null;

  @override
  Future<MoodEntryDto> create(MoodEntryDto dto) async => dto;

  @override
  Future<MoodEntryDto> update(MoodEntryDto dto) async => dto;

  @override
  Future<void> delete({required String userId, required String id}) async {}
}

/// Integration-test [MoodSyncManager] — bootstrap, shutdown, and kick are
/// no-ops so the router's auth-transition listener can read the provider
/// without dragging in real Firestore / Drift / connectivity_plus.
///
/// Mirrors the unit-test pattern in `mood_repository_impl_test.dart`. The
/// constructor still requires a working Drift DAO surface (the parent
/// class stores the references), so we hand it an in-memory `MoodDatabase`
/// that the test owns and disposes via [dispose].
class FakeSyncManager extends MoodSyncManager {
  FakeSyncManager._({
    required super.moodDao,
    required super.syncQueueDao,
    required super.remote,
    required super.connectivity,
    required super.deviceIdGetter,
    required super.prefs,
  }) : super(mapper: const MoodEntryMapper());

  /// Build a [FakeSyncManager] with a fresh in-memory Drift DB and
  /// disposable connectivity stream. Caller owns lifetime — call
  /// [dispose] in tearDown.
  static Future<FakeSyncManager> create() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = MoodDatabase.forTesting(NativeDatabase.memory());
    final connectivity = StreamController<bool>.broadcast();
    final manager = FakeSyncManager._(
      moodDao: db.moodDao,
      syncQueueDao: db.syncQueueDao,
      remote: _NoopFirestoreDatasource(),
      connectivity: connectivity.stream,
      deviceIdGetter: () => 'integ-device',
      prefs: prefs,
    );
    manager._db = db;
    manager._connectivity = connectivity;
    return manager;
  }

  late final MoodDatabase _db;
  late final StreamController<bool> _connectivity;

  int bootstrapCalls = 0;
  int shutdownCalls = 0;

  @override
  void kick() {
    // No-op — production drainer would touch Firestore.
  }

  @override
  Future<void> bootstrap(String uid) async {
    bootstrapCalls += 1;
  }

  @override
  Future<void> shutdown() async {
    shutdownCalls += 1;
    // Cancel the parent's connectivity sub + poll timer for a clean
    // tearDown — without this, dangling timers leak across tests.
    await super.shutdown();
  }

  /// Release Drift + connectivity stream. Call from tearDown.
  Future<void> dispose() async {
    await shutdown();
    await _connectivity.close();
    await _db.close();
  }
}
