import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodbloom/features/tokens/presentation/widgets/token_balance_chip.dart';

/// Wraps [child] in a fully-themed `MaterialApp` so the chip's
/// `Theme.of(context).extension<MbColors>()` lookup resolves. Mirrors
/// the harness in `apps/mobile/test/features/garden/presentation/widgets/`.
Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(extensions: [MbColors.light()]),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('TokenBalanceChip', () {
    testWidgets('renders the balance number', (tester) async {
      await tester.pumpWidget(_wrap(const TokenBalanceChip(balance: 27)));
      expect(find.text('27'), findsOneWidget);
    });

    testWidgets('renders zero balance without crash', (tester) async {
      await tester.pumpWidget(_wrap(const TokenBalanceChip(balance: 0)));
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('exposes "<balance> tokens" semantics label', (tester) async {
      await tester.pumpWidget(_wrap(const TokenBalanceChip(balance: 42)));
      // Walk the semantics tree for a node whose merged label exactly
      // matches '42 tokens'. This is what TalkBack / VoiceOver
      // announce — accessibility users get the same signal as sighted
      // users.
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel('42 tokens'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('renders a flower icon (no money/coin glyph)', (tester) async {
      // Anti-pattern guardrail: tokens are tied to the garden metaphor
      // and unlock cosmetic flower skins, NOT money. The icon must
      // stay a flower glyph so users don't read "currency" into it.
      await tester.pumpWidget(_wrap(const TokenBalanceChip(balance: 1)));
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.local_florist);
    });
  });
}
