import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/garden/data/intervention_state_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('InterventionStateStorage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Future<InterventionStateStorage> makeStorage() async {
      final prefs = await SharedPreferences.getInstance();
      return InterventionStateStorage(prefs);
    }

    test('reads return null on first launch', () async {
      final storage = await makeStorage();
      expect(storage.readLastTriggeredAt(), isNull);
      expect(storage.readFirstTriggeredAt(), isNull);
    });

    test('write/read round-trip preserves the timestamp (within ms)', () async {
      final storage = await makeStorage();
      final t = DateTime(2026, 5, 1, 10, 30, 45);

      await storage.writeLastTriggeredAt(t);
      await storage.writeFirstTriggeredAt(t);

      // Tolerate a small drift only because UTC↔local round-trips can
      // round at the millisecond boundary on some platforms.
      expect(
        storage.readLastTriggeredAt()!.isAtSameMomentAs(t),
        isTrue,
        reason: 'readLastTriggeredAt mismatch',
      );
      expect(
        storage.readFirstTriggeredAt()!.isAtSameMomentAs(t),
        isTrue,
        reason: 'readFirstTriggeredAt mismatch',
      );
    });

    test('reads return null for malformed stored ISO strings', () async {
      SharedPreferences.setMockInitialValues({
        'intervention.last_triggered_at_iso8601': 'not-a-date',
      });
      final storage = await makeStorage();
      expect(storage.readLastTriggeredAt(), isNull);
    });

    test('clearFirstTriggeredAt removes only the first anchor', () async {
      final storage = await makeStorage();
      final t = DateTime(2026, 5, 1, 10);
      await storage.writeLastTriggeredAt(t);
      await storage.writeFirstTriggeredAt(t);

      await storage.clearFirstTriggeredAt();

      expect(storage.readFirstTriggeredAt(), isNull);
      expect(storage.readLastTriggeredAt(), isNotNull);
    });

    group('maybeClearFirstTriggeredAt lifecycle', () {
      test('no last anchor → no-op', () async {
        final storage = await makeStorage();
        await storage.writeFirstTriggeredAt(DateTime(2026, 4, 1));

        await storage.maybeClearFirstTriggeredAt(
          now: DateTime(2026, 5, 1),
          currentlyTriggered: false,
        );
        expect(storage.readFirstTriggeredAt(), isNotNull);
      });

      test('last anchor < 48h ago → no clear', () async {
        final storage = await makeStorage();
        final now = DateTime(2026, 5, 1, 12);
        await storage.writeLastTriggeredAt(
          now.subtract(const Duration(hours: 12)),
        );
        await storage.writeFirstTriggeredAt(
          now.subtract(const Duration(days: 5)),
        );

        await storage.maybeClearFirstTriggeredAt(
          now: now,
          currentlyTriggered: false,
        );
        expect(storage.readFirstTriggeredAt(), isNotNull);
      });

      test(
        'last anchor ≥ 48h ago AND not currently triggering → clear',
        () async {
          final storage = await makeStorage();
          final now = DateTime(2026, 5, 1, 12);
          await storage.writeLastTriggeredAt(
            now.subtract(const Duration(hours: 49)),
          );
          await storage.writeFirstTriggeredAt(
            now.subtract(const Duration(days: 5)),
          );

          await storage.maybeClearFirstTriggeredAt(
            now: now,
            currentlyTriggered: false,
          );
          expect(storage.readFirstTriggeredAt(), isNull);
        },
      );

      test('currently triggering → never clears even past 48h', () async {
        final storage = await makeStorage();
        final now = DateTime(2026, 5, 1, 12);
        await storage.writeLastTriggeredAt(
          now.subtract(const Duration(hours: 49)),
        );
        await storage.writeFirstTriggeredAt(
          now.subtract(const Duration(days: 5)),
        );

        await storage.maybeClearFirstTriggeredAt(
          now: now,
          currentlyTriggered: true,
        );
        expect(storage.readFirstTriggeredAt(), isNotNull);
      });
    });
  });
}
