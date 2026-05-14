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
import 'package:moodbloom/features/tokens/domain/entities/token_balance.dart';
import 'package:moodbloom/features/tokens/domain/repositories/skin_repository.dart';
import 'package:moodbloom/features/tokens/domain/repositories/token_repository.dart';
import 'package:moodbloom/features/tokens/domain/services/skin_catalog.dart';
import 'package:moodbloom/features/tokens/domain/skin_failure.dart';
import 'package:moodbloom/features/tokens/domain/token_failure.dart';
import 'package:moodbloom/features/tokens/domain/entities/token_award.dart';
import 'package:moodbloom/features/tokens/presentation/widgets/locked_skin_chip.dart';
import 'package:moodbloom/features/tokens/presentation/widgets/skin_modal_sheet.dart';

import '../../../../helpers/pump_app.dart';

/// Hand-rolled fake `SkinRepository` — mirrors the pattern in
/// `unlock_flower_skin_test.dart`. Streams a configurable [SkinState].
class _FakeSkinRepo implements SkinRepository {
  _FakeSkinRepo(this._state);

  final SkinState _state;

  @override
  Future<Result<SkinState, SkinFailure>> select({
    required String userId,
    required FlowerSpecies species,
    required String skinId,
  }) async {
    return Ok(_state);
  }

  @override
  Future<Result<SkinState, SkinFailure>> unlockAndSelect({
    required String userId,
    required FlowerSkin skin,
  }) async {
    return Ok(_state);
  }

  @override
  Stream<SkinState> watchSkinState({required String userId}) =>
      Stream<SkinState>.value(_state);
}

/// Hand-rolled fake `TokenRepository` — emits a single [TokenBalance]
/// snapshot so the modal can read it for the affordable-vs-unaffordable
/// LockedSkinChip discriminator.
class _FakeTokenRepo implements TokenRepository {
  _FakeTokenRepo(this._balance);

  final int _balance;

  @override
  Future<Result<TokenAward, TokenFailure>> awardForLog({
    required String userId,
  }) async {
    return const Err(TokenFailure.unknown('not exercised in widget test'));
  }

  @override
  Stream<TokenBalance> watchBalance({required String userId}) =>
      Stream<TokenBalance>.value(
        TokenBalance(
          balance: _balance,
          earnedToday: 0,
          lastEarnedDate: null,
        ),
      );
}

Stream<AppUser?> _userStream(AppUser? user) {
  final controller = StreamController<AppUser?>();
  controller.add(user);
  return controller.stream;
}

/// Pumps the modal directly (not via `showModalBottomSheet`) so we can
/// assert on its widget tree synchronously. The production `show`
/// helper opens the same widget inside a bottom sheet — the widget
/// content itself is what the assertions exercise, so a direct mount
/// is the lighter-weight path for unit-level widget tests.
Future<void> _pumpModal(
  WidgetTester tester, {
  required SkinState skinState,
  required int balance,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await pumpApp(
    tester,
    overrides: [
      currentUserStreamProvider.overrideWith(
        (_) => _userStream(const AppUser(uid: 'u-1', email: 'u@example.com')),
      ),
      skinRepositoryProvider.overrideWithValue(_FakeSkinRepo(skinState)),
      tokenRepositoryProvider.overrideWithValue(_FakeTokenRepo(balance)),
    ],
    child: const Scaffold(body: SkinModalSheet()),
  );
  // Settle the streams without entering the modal's idle animation loop
  // (there isn't one, but mirror the pattern from garden_screen_test).
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('SkinModalSheet — TC-8 locked-state display', () {
    testWidgets('renders one section header per species (all six)', (
      tester,
    ) async {
      await _pumpModal(
        tester,
        skinState: SkinState.empty(),
        balance: 0,
      );

      // Section headers are rendered in uppercase — see
      // `_SpeciesSection._humanSpeciesName`. Asserting on the rendered
      // header text is the most stable selector (no internal-only key).
      expect(find.text('SUNFLOWER'), findsOneWidget);
      expect(find.text('FORGET-ME-NOT'), findsOneWidget);
      expect(find.text('DAISY'), findsOneWidget);
      expect(find.text('POPPY'), findsOneWidget);
      expect(find.text('FERN'), findsOneWidget);
      expect(find.text('LAVENDER'), findsOneWidget);
    });

    testWidgets(
      'locked non-default skins each render exactly one LockedSkinChip',
      (tester) async {
        // Empty unlocked pool → every non-default skin in the catalog is
        // locked, so the chip count matches the catalog's non-default
        // count.
        await _pumpModal(
          tester,
          skinState: SkinState.empty(),
          // Zero balance — everything is unaffordable, but we are not
          // testing affordability here, only chip presence.
          balance: 0,
        );

        final lockedCount =
            SkinCatalog.all().where((s) => !s.isDefault).length;
        expect(
          find.byType(LockedSkinChip),
          findsNWidgets(lockedCount),
          reason:
              'one LockedSkinChip per non-default catalog skin '
              'when the user has unlocked none of them',
        );
        // Every chip should display its cost as text — the catalog only
        // uses three tier prices (50 / 100 / 150).
        expect(find.text('50'), findsWidgets);
        expect(find.text('100'), findsWidgets);
        expect(find.text('150'), findsWidgets);
      },
    );

    testWidgets(
      'affordable LockedSkinChips have affordable: true; unaffordable have '
      'affordable: false',
      (tester) async {
        // Balance 75 → tier-50 skins are affordable, tier-100 and
        // tier-150 are not. We discriminate using the chip's public
        // `affordable` field (set by the modal based on
        // `userBalance >= skin.cost`). This is the documented seam in
        // `locked_skin_chip.dart` — assertion mechanism: read each
        // LockedSkinChip widget's `affordable` field.
        await _pumpModal(
          tester,
          skinState: SkinState.empty(),
          balance: 75,
        );

        final chips = tester
            .widgetList<LockedSkinChip>(find.byType(LockedSkinChip))
            .toList();
        // Tier prices in the catalog: 50, 100, 150. With balance=75 the
        // tier-50 chips must be affordable; the rest must be unaffordable.
        final affordable = chips.where((c) => c.affordable).toList();
        final unaffordable = chips.where((c) => !c.affordable).toList();

        // Cross-check counts against catalog so an accidental catalog
        // expansion immediately flags this test.
        final tier50 = SkinCatalog.all()
            .where((s) => !s.isDefault && s.cost == 50)
            .length;
        final tier100Plus = SkinCatalog.all()
            .where((s) => !s.isDefault && s.cost > 50)
            .length;
        expect(
          affordable.length,
          tier50,
          reason: 'one affordable chip per tier-50 skin at balance=75',
        );
        expect(
          unaffordable.length,
          tier100Plus,
          reason: 'tier-100 and tier-150 chips are unaffordable at balance=75',
        );
        // And the affordable chips' costs must all be ≤ balance.
        for (final c in affordable) {
          expect(c.cost <= 75, isTrue, reason: 'cost ${c.cost} exceeds 75');
        }
        for (final c in unaffordable) {
          expect(c.cost > 75, isTrue, reason: 'cost ${c.cost} ≤ 75');
        }
      },
    );

    testWidgets(
      'default skins (one per species) render without a LockedSkinChip',
      (tester) async {
        await _pumpModal(
          tester,
          skinState: SkinState.empty(),
          balance: 0,
        );

        // Defaults are `Selected` by default (TC-10 — see modal code:
        // `effectiveSelectedId = selectedId ?? defaultSkin.skinId`). They
        // render with the "Selected" pill, never a LockedSkinChip.
        // Six species → six "Selected" pills (the default-of-each-species
        // is the implicit selection when SkinState is empty).
        expect(find.text('Selected'), findsNWidgets(6));

        // Spot-check: a chip with cost 0 must never be rendered.
        for (final chip in tester.widgetList<LockedSkinChip>(
          find.byType(LockedSkinChip),
        )) {
          expect(
            chip.cost > 0,
            isTrue,
            reason: 'LockedSkinChip should never be rendered for free defaults',
          );
        }
      },
    );

    testWidgets(
      'unlocked non-default skin renders WITHOUT a LockedSkinChip',
      (tester) async {
        // Pre-unlock `sunflower_sunset` (cost: 50). With it in the pool
        // and selected, the sunflower section should NOT render a chip
        // for sunset; the default sunflower also has no chip. Locked
        // sunflower alternates (e.g. `sunflower_moonlit` at cost 100)
        // still render their chip.
        const sunflowerSunsetId = 'sunflower_sunset';
        final state = SkinState(
          unlockedBySpecies: const {
            FlowerSpecies.sunflower: {sunflowerSunsetId},
          },
          selectedBySpecies: const {
            FlowerSpecies.sunflower: sunflowerSunsetId,
          },
        );
        await _pumpModal(tester, skinState: state, balance: 0);

        // Two text strings make this fully observable:
        //   1. "Sunset Sunflower" is the now-owned skin's displayName.
        //   2. "Selected" appears 6× — one per species default — EXCEPT
        //      the sunflower row, which now shows "Selected" on the
        //      sunset card AND "Tap to select" on the classic card
        //      (owned → not selected). Total "Selected" pills: still 6
        //      (5 species defaults + sunset).
        expect(find.text('Sunset Sunflower'), findsOneWidget);
        expect(find.text('Selected'), findsNWidgets(6));
        // The classic-sunflower default is now owned-not-selected, so
        // its trailing text reads "Tap to select".
        expect(find.text('Tap to select'), findsOneWidget);

        // Total LockedSkinChip count = non-default catalog size − 1
        // (sunflower_sunset is no longer locked).
        final nonDefaults = SkinCatalog.all()
            .where((s) => !s.isDefault)
            .length;
        expect(find.byType(LockedSkinChip), findsNWidgets(nonDefaults - 1));
      },
    );
  });
}
