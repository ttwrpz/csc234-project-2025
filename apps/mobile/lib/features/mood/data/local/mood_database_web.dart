// Web stub for the MoodDatabase connector. Selected via the conditional
// import in mood_database.dart when `dart.library.io` is NOT available.
//
// Why a stub? The Drift web port (OPFS via sql.js) is fragile under Safari
// quotas, so the Web build routes through the Firestore-only fallback path:
// `offlineFirstEnabledProvider` defaults to `!kIsWeb`, and `MoodRepositoryImpl`
// never reads from the DAOs on Web, so this connector is never invoked.
//
// LazyDatabase defers actual opening until first query. Constructing the
// MoodDatabase on Web is therefore safe: the throw only fires if some future
// caller bypasses the offline-first guard. That's the right failure mode —
// loud and clear, not silent corruption.

import 'package:drift/drift.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    throw UnsupportedError(
      'MoodDatabase is not available on Web. The repository must route through '
      'the Firestore-only fallback path.',
    );
  });
}
