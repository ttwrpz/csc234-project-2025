import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/disclaimer/data/providers.dart';
import 'package:moodbloom/features/disclaimer/domain/disclaimer_copy.dart';
import 'package:moodbloom/features/disclaimer/domain/disclaimer_failure.dart';
import 'package:moodbloom/features/disclaimer/domain/repositories/disclaimer_repository.dart';
import 'package:moodbloom/features/disclaimer/presentation/widgets/disclaimer_ack_dialog.dart';

/// Recording fake — captures every userId passed to [ack] so the test
/// can assert the dialog wired the right argument from `widget.userId`.
class _FakeDisclaimerRepo implements DisclaimerRepository {
  final List<String> ackedUsers = [];

  Result<void, DisclaimerFailure> nextAckResult = const Ok(null);

  @override
  Future<Result<void, DisclaimerFailure>> ack({required String userId}) async {
    ackedUsers.add(userId);
    return nextAckResult;
  }

  @override
  Stream<bool> watchAckState({required String userId}) =>
      const Stream<bool>.empty();
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  required _FakeDisclaimerRepo repo,
  required String userId,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [disclaimerRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: buildLightTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    DisclaimerAckDialog.show(context, userId: userId),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('DisclaimerAckDialog', () {
    testWidgets(
      'renders the full disclaimer + the locked "I understand" button',
      (tester) async {
        final repo = _FakeDisclaimerRepo();
        await _pumpDialog(tester, repo: repo, userId: 'u-1');

        expect(find.text(DisclaimerCopy.full), findsOneWidget);
        expect(find.text(DisclaimerCopy.ackButton), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);
      },
    );

    testWidgets(
      'tapping "I understand" calls ack(userId) once and pops the dialog',
      (tester) async {
        final repo = _FakeDisclaimerRepo();
        await _pumpDialog(tester, repo: repo, userId: 'u-tester');

        await tester.tap(find.text(DisclaimerCopy.ackButton));
        await tester.pumpAndSettle();

        expect(repo.ackedUsers, ['u-tester']);
        expect(
          find.text(DisclaimerCopy.full),
          findsNothing,
          reason: 'dialog must be popped after the ack write completes',
        );
      },
    );

    testWidgets(
      'is barrier-non-dismissible — tapping outside does NOT close it',
      (tester) async {
        final repo = _FakeDisclaimerRepo();
        await _pumpDialog(tester, repo: repo, userId: 'u-1');

        // Tap a point well outside the AlertDialog body. Without
        // barrierDismissible: false the dialog would pop on outside tap.
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(
          find.text(DisclaimerCopy.full),
          findsOneWidget,
          reason: 'mandatory ack must require an explicit button tap',
        );
        expect(
          repo.ackedUsers,
          isEmpty,
          reason: 'no ack must fire on a barrier tap',
        );
      },
    );
  });
}
