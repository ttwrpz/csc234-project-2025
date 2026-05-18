import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';

import '../domain/entities/pin.dart';
import '../domain/entities/pin_hash.dart';
import '../domain/entities/pin_setup_failure.dart';
import '../domain/entities/pin_verify_failure.dart';
import '../domain/repositories/pin_repository.dart';
import '../domain/services/pin_hasher.dart';
import 'datasources/pin_firestore_datasource.dart';

/// Repository implementation for the PIN fallback factor.
///
/// Composes the [PinFirestoreDatasource] (storage) with a [PinHasher]
/// (PBKDF2-SHA-256 derivation + constant-time comparison) to provide
/// the domain-facing setup / verify / remove triad.
///
/// **Verification is client-side.** The repository reads the stored
/// hash doc, re-derives PBKDF2 with the user-entered PIN + stored
/// salt, and compares the two with [PinHasher.constantTimeEquals].
/// The raw PIN never leaves the device; only the derived hash bytes
/// are compared.
class PinRepositoryImpl implements PinRepository {
  PinRepositoryImpl({
    required PinFirestoreDatasource firestore,
    required PinHasher hasher,
    DateTime Function() clock = _systemClock,
    Logger logger = const Logger('auth.pin'),
  }) : _firestore = firestore,
       _hasher = hasher,
       _clock = clock,
       _logger = logger;

  final PinFirestoreDatasource _firestore;
  final PinHasher _hasher;
  final DateTime Function() _clock;
  final Logger _logger;

  static DateTime _systemClock() => DateTime.now().toUtc();

  /// Rate-limit ladder.
  static const int _softLockThreshold = 5;
  static const Duration _softLockDuration = Duration(seconds: 60);
  static const int _hardLockThreshold = 10;
  static const Duration _hardLockDuration = Duration(minutes: 30);

  @override
  Future<PinHash?> read({required String userId}) async {
    try {
      final raw = await _firestore.read(userId: userId);
      if (raw == null) return null;
      return _fromFirestoreData(raw);
    } on FirebaseException catch (e) {
      // Rate-limit gate rejection surfaces as permission-denied at the
      // rules layer. The Settings "PIN set?" read should never hit that
      // — only verify reads do, because the lock is on resource.data —
      // so we treat a denial here as a real error and return null
      // (callers see "no PIN" rather than crash).
      _logger.warn('pin read failed: ${e.code}');
      return null;
    }
  }

  @override
  Future<Result<void, PinSetupFailure>> setup({
    required String userId,
    required Pin pin,
  }) async {
    try {
      final salt = _hasher.newSalt();
      // `deriveAsync` runs PBKDF2 on a Flutter compute() worker isolate
      // so the UI thread isn't pinned for ~1–3 s during setup. See
      // PinHasherImpl.deriveAsync for the off-isolate plumbing.
      final hash = await _hasher.deriveAsync(
        pinDigits: pin.digits,
        salt: salt,
        iterations: PinHasher.minIterations,
      );
      await _firestore.write(
        userId: userId,
        data: _toFirestoreData(
          algorithm: _hasher.algorithm,
          iterations: PinHasher.minIterations,
          saltBase64: base64.encode(salt),
          hashBase64: base64.encode(hash),
          createdAt: _clock(),
          failedAttempts: 0,
          lockedUntil: null,
        ),
      );
      return const Ok(null);
    } on FirebaseException catch (e) {
      _logger.warn('pin setup failed: ${e.code}');
      return const Err(PinSetupFailure.storage());
    } catch (e) {
      _logger.error('pin setup unexpected', error: e);
      return Err(PinSetupFailure.unknown(e.runtimeType));
    }
  }

  @override
  Future<Result<void, PinVerifyFailure>> verify({
    required String userId,
    required Pin pin,
  }) async {
    final Map<String, dynamic>? raw;
    try {
      raw = await _firestore.read(userId: userId);
    } on FirebaseException catch (e) {
      // permission-denied during a verify read most likely means the
      // rule-level rate-limit (lockedUntil > now) is in effect. We
      // can't read the doc to confirm — surface the locked failure
      // with the lower bound (now + soft lock) so the UI still shows
      // a sensible countdown. The actual remaining lock time is read
      // on the next attempt that succeeds.
      if (e.code == 'permission-denied') {
        return Err(
          PinVerifyFailure.locked(until: _clock().add(_softLockDuration)),
        );
      }
      _logger.warn('pin verify read failed: ${e.code}');
      return const Err(PinVerifyFailure.storage());
    }

    if (raw == null) {
      return const Err(PinVerifyFailure.noPinSet());
    }

    final PinHash stored;
    try {
      stored = _fromFirestoreData(raw);
    } catch (e) {
      _logger.error('pin doc malformed', error: e);
      return Err(PinVerifyFailure.unknown(e.runtimeType));
    }

    // Client-side recheck of the lockout window. The rule enforces it
    // too, but we'd rather not waste a round trip if we already know.
    final now = _clock();
    final lockedUntil = stored.lockedUntil;
    if (lockedUntil != null && lockedUntil.isAfter(now)) {
      return Err(PinVerifyFailure.locked(until: lockedUntil));
    }

    final salt = base64.decode(stored.saltBase64);
    final expectedHash = base64.decode(stored.hashBase64);
    // Off-main-isolate PBKDF2 — without this, verify() pins the UI
    // thread for the full 100 000-iteration loop (~1–3 s on mid-range
    // Android). With `deriveAsync` the spinner stays smooth and the
    // user can still hit back / cancel during verify.
    final computed = await _hasher.deriveAsync(
      pinDigits: pin.digits,
      salt: salt,
      iterations: stored.iterations,
    );

    if (_hasher.constantTimeEquals(computed, expectedHash)) {
      // Success — reset the rate-limit anchor.
      try {
        await _firestore.clearFailures(userId: userId);
      } on FirebaseException catch (e) {
        // The verification itself succeeded; failing to clear the
        // anchor is a latent issue but not a user-blocking one. Log
        // and continue.
        _logger.warn('pin clearFailures post-success failed: ${e.code}');
      }
      return const Ok(null);
    }

    // Wrong PIN. Bump the rate-limit anchor. The thresholds escalate:
    //   5 → soft lock (60s)
    //  10 → hard lock (30min)
    final nextAttempts = stored.failedAttempts + 1;
    final newLockUntil = _lockedUntilFor(nextAttempts, now);
    try {
      await _firestore.bumpFailure(
        userId: userId,
        newFailedAttempts: nextAttempts,
        lockedUntil: newLockUntil,
      );
    } on FirebaseException catch (e) {
      _logger.warn('pin bumpFailure failed: ${e.code}');
      // The user still entered the wrong PIN — surface that with the
      // best-effort remaining count even if the bump didn't land.
    }

    if (newLockUntil != null) {
      return Err(PinVerifyFailure.locked(until: newLockUntil));
    }
    final remaining = (_softLockThreshold - nextAttempts).clamp(
      0,
      _softLockThreshold,
    );
    return Err(PinVerifyFailure.wrong(remainingAttempts: remaining));
  }

  @override
  Future<Result<void, PinSetupFailure>> remove({required String userId}) async {
    // The Firestore rule denies client delete. "Remove" is therefore
    // implemented as a write of a random unrecoverable hash. The salt
    // is fresh random bytes and
    // the derived key is also random — there is no PIN that derives
    // to this hash, so future verify attempts always fail (and the
    // owner can re-run setup, which overwrites this sentinel).
    try {
      final salt = _hasher.newSalt();
      // Random "hash" the same length as the real derived key. We
      // generate it the same way as the salt; nobody will derive to
      // these bytes from any real PIN, so the verify path is closed.
      final randomHash = _hasher.newSalt() + _hasher.newSalt(); // 32 bytes
      await _firestore.write(
        userId: userId,
        data: _toFirestoreData(
          algorithm: _hasher.algorithm,
          iterations: PinHasher.minIterations,
          saltBase64: base64.encode(salt),
          hashBase64: base64.encode(randomHash),
          createdAt: _clock(),
          failedAttempts: 0,
          lockedUntil: null,
        ),
      );
      return const Ok(null);
    } on FirebaseException catch (e) {
      _logger.warn('pin remove failed: ${e.code}');
      return const Err(PinSetupFailure.storage());
    }
  }

  /// Maps a Firestore document map to a [PinHash]. Throws on malformed
  /// data; the caller wraps in a failure type.
  PinHash _fromFirestoreData(Map<String, dynamic> raw) {
    final createdAtTs = raw['createdAt'];
    final lockedUntilTs = raw['lockedUntil'];
    DateTime? lockedUntil;
    if (lockedUntilTs is Timestamp) {
      lockedUntil = lockedUntilTs.toDate().toUtc();
    }
    return PinHash(
      algorithm: raw['algorithm'] as String,
      iterations: raw['iterations'] as int,
      saltBase64: raw['saltBase64'] as String,
      hashBase64: raw['hashBase64'] as String,
      createdAt: createdAtTs is Timestamp
          ? createdAtTs.toDate().toUtc()
          : DateTime.parse(createdAtTs as String).toUtc(),
      failedAttempts: (raw['failedAttempts'] as num?)?.toInt() ?? 0,
      lockedUntil: lockedUntil,
    );
  }

  Map<String, dynamic> _toFirestoreData({
    required String algorithm,
    required int iterations,
    required String saltBase64,
    required String hashBase64,
    required DateTime createdAt,
    required int failedAttempts,
    required DateTime? lockedUntil,
  }) {
    return {
      'algorithm': algorithm,
      'iterations': iterations,
      'saltBase64': saltBase64,
      'hashBase64': hashBase64,
      'createdAt': Timestamp.fromDate(createdAt),
      'failedAttempts': failedAttempts,
      'lockedUntil': lockedUntil == null
          ? null
          : Timestamp.fromDate(lockedUntil),
    };
  }

  /// Lockout ladder. At 10 failures → hard lock (30 min); at 5 → soft
  /// lock (60 s); otherwise null (next attempt is allowed).
  DateTime? _lockedUntilFor(int nextAttempts, DateTime now) {
    if (nextAttempts >= _hardLockThreshold) return now.add(_hardLockDuration);
    if (nextAttempts >= _softLockThreshold) return now.add(_softLockDuration);
    return null;
  }
}
