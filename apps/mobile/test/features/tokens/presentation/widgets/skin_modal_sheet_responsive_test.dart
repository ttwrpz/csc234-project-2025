import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/auth/data/providers.dart';
import 'package:moodbloom/features/auth/domain/entities/app_user.dart';
import 'package:moodbloom/features/garden/domain/entities/flower_species.dart';
import 'package:moodbloom/features/tokens/data/providers.dart';
import 'package:moodbloom/features/tokens/domain/entities/flower_skin.dart';
import 'package:moodbloom/features/tokens/domain/entities/skin_state.dart';
import 'package:moodbloom/features/tokens/domain/entities/token_award.dart';
import 'package:moodbloom/features/tokens/domain/entities/token_balance.dart';
import 'package:moodbloom/features/tokens/domain/repositories/skin_repository.dart';
import 'package:moodbloom/features/tokens/domain/repositories/token_repository.dart';
import 'package:moodbloom/features/tokens/domain/skin_failure.dart';
import 'package:moodbloom/features/tokens/domain/token_failure.dart';
import 'package:moodbloom/features/tokens/presentation/widgets/skin_modal_sheet.dart';

import '../../../../helpers/pump_app.dart';

/// Minimal fake — the responsive test only needs the modal to mount,
/// not to drive a select/unlock flow.
class _FakeSkinRepo implements SkinRepository {
  @override
  Future<Result<SkinState, SkinFailure>> select({
    required String userId,
    required FlowerSpecies species,
    required String skinId,
  }) async {
    return Ok(SkinState.empty());
  }

  @override
  Future<Result<SkinState, SkinFailure>> unlockAndSelect({
    required String userId,
    required FlowerSkin skin,
  }) async {
    return Ok(SkinState.empty());
  }

  @override
  Stream<SkinState> watchSkinState({required String userId}) =>
      Stream<SkinState>.value(SkinState.empty());
}

class _FakeTokenRepo implements TokenRepository {
  @override
  Future<Result<TokenAward, TokenFailure>> awardForLog({
    required String userId,
  }) async {
    return const Err(TokenFailure.unknown('not exercised in widget test'));
  }

  @override
  Future<Result<TokenAward, TokenFailure>> grantDebug({
    required String userId,
    required int amount,
  }) async => const Err(TokenFailure.unknown('not exercised in widget test'));

  @override
  Stream<TokenBalance> watchBalance({required String userId}) =>
      Stream<TokenBalance>.value(
        const TokenBalance(balance: 0, earnedToday: 0, lastEarnedDate: null),
      );
}

Stream<AppUser?> _userStream() {
  final controller = StreamController<AppUser?>();
  controller.add(const AppUser(uid: 'u-1', email: 'u@example.com'));
  return controller.stream;
}

/// Pumps a host page with an "open" button that calls
/// `SkinModalSheet.show(context)`. We override `MediaQuery` directly so
/// the launcher's `MediaQuery.sizeOf(context).width` check is
/// independent of the test surface's window-size mechanics (calling
/// `binding.setSurfaceSize` and `tester.view.physicalSize` is fragile
/// across DPRs and the test framework's view-attachment timing — a
/// `MediaQuery` wrapper bypasses both).
Future<void> _pumpHost(WidgetTester tester, Size size) async {
  // Resize the surface too so the showDialog/showModalBottomSheet
  // routes that read `View.of(context)` for their barrier layout get
  // sane bounds. The launcher itself reads from `MediaQuery` so the
  // override below is what governs the chrome selection.
  // Pin physicalSize + devicePixelRatio explicitly on the TestFlutterView.
  // setSurfaceSize alone leaves DPR at the test default (3.0 on Android-
  // emulator), so a "1440 dp desktop" surface would be reported as 480 dp
  // to MediaQuery.sizeOf and the responsive launcher would fire the wrong
  // chrome.
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await pumpApp(
    tester,
    overrides: [
      currentUserStreamProvider.overrideWith((_) => _userStream()),
      skinRepositoryProvider.overrideWithValue(_FakeSkinRepo()),
      tokenRepositoryProvider.overrideWithValue(_FakeTokenRepo()),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => SkinModalSheet.show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('SkinModalSheet — Wave B responsive launcher', () {
    testWidgets('phone viewport (360x800) presents a BottomSheet, no Dialog', (
      tester,
    ) async {
      await _pumpHost(tester, const Size(360, 800));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Absence of `Dialog` is the load-bearing proof that the phone
      // launcher used showModalBottomSheet — `BottomSheet` as a widget
      // type is not always surfaced in the flutter_test tree (modal-
      // bottom-sheet's internal wrapper varies across Material versions).
      expect(
        find.byType(Dialog),
        findsNothing,
        reason: 'phone-width launcher MUST NOT use a Dialog',
      );
      expect(find.byType(SkinModalSheet), findsOneWidget);
    });

    testWidgets(
      'tablet viewport (768x1024) presents a centered Dialog at 560 dp max',
      (tester) async {
        await _pumpHost(tester, const Size(768, 1024));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsOneWidget);
        expect(
          find.byType(BottomSheet),
          findsNothing,
          reason: 'tablet launcher MUST promote the modal to a centered dialog',
        );
        expect(find.byType(SkinModalSheet), findsOneWidget);

        // The ConstrainedBox that wraps the SkinModalSheet inside the
        // dialog caps width at 560 dp on tablet. We assert on the
        // descendant constraint that sits directly above the modal so
        // unrelated `ConstrainedBox` nodes (e.g. Material's internal
        // sizing) don't false-positive.
        final constrained = tester.widget<ConstrainedBox>(
          find
              .ancestor(
                of: find.byType(SkinModalSheet),
                matching: find.byType(ConstrainedBox),
              )
              .first,
        );
        expect(constrained.constraints.maxWidth, 560);
      },
    );

    testWidgets(
      'desktop viewport (1440x900) presents a centered Dialog at 640 dp max',
      (tester) async {
        await _pumpHost(tester, const Size(1440, 900));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.byType(Dialog), findsOneWidget);
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.byType(SkinModalSheet), findsOneWidget);

        final constrained = tester.widget<ConstrainedBox>(
          find
              .ancestor(
                of: find.byType(SkinModalSheet),
                matching: find.byType(ConstrainedBox),
              )
              .first,
        );
        expect(
          constrained.constraints.maxWidth,
          640,
          reason:
              'desktop widens the skin-grid dialog so more cards fit in view',
        );
      },
    );
  });
}
