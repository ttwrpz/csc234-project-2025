import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/providers.dart';
import '../../data/providers.dart';
import '../../domain/entities/garden_skin.dart';
import '../../domain/entities/skin_state.dart';
import '../../domain/skin_failure.dart';

/// Modal confirmation sheet for buying + equipping a global garden skin.
///
/// Layout per `SkinPurchaseConfirmScreen` in `skin-shop.jsx`:
///   * 120x120 preview window (gradient bg + large happy-mood plant)
///   * Skin name (Fraunces 22) + tagline (Nunito 13 mb.textDim)
///   * Cost breakdown card: skin cost / current balance / after
///   * Disclaimer: "Skins apply to every plant..."
///   * Primary action: "Purchase & equip" (with check leading)
///   * Ghost action: "Maybe later"
///
/// Presentation:
///   * Phone (<MbBreakpoints.modalDialog): bottom sheet, ~92% height.
///   * Tablet+: centered dialog, max width 560 dp.
class SkinPurchaseConfirmSheet extends ConsumerStatefulWidget {
  const SkinPurchaseConfirmSheet({
    super.key,
    required this.skin,
    required this.currentBalance,
  });

  final GardenSkin skin;
  final int currentBalance;

  /// Responsive launcher - bottom sheet on phone, centered dialog on
  /// tablet+. Resolves to `true` on a successful purchase, `false`
  /// otherwise (cancellation, error, or unmounted).
  static Future<bool> show(
    BuildContext context, {
    required GardenSkin skin,
    required int currentBalance,
  }) async {
    final size = MediaQuery.sizeOf(context);
    if (size.width < MbBreakpoints.modalDialog) {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SkinPurchaseConfirmSheet(
          skin: skin,
          currentBalance: currentBalance,
        ),
      );
      return ok ?? false;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusSky),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SkinPurchaseConfirmSheet(
            skin: skin,
            currentBalance: currentBalance,
          ),
        ),
      ),
    );
    return ok ?? false;
  }

  @override
  ConsumerState<SkinPurchaseConfirmSheet> createState() =>
      _SkinPurchaseConfirmSheetState();
}

class _SkinPurchaseConfirmSheetState
    extends ConsumerState<SkinPurchaseConfirmSheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final isPhone =
        MediaQuery.sizeOf(context).width < MbBreakpoints.modalDialog;
    final body = _body(mb);
    if (!isPhone) return body;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: mb.bg,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(MoodBloomSpacing.radiusSky),
            ),
          ),
          child: SingleChildScrollView(controller: controller, child: body),
        ),
      ),
    );
  }

  Widget _body(MbColors mb) {
    final after = widget.currentBalance - widget.skin.cost;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MoodBloomSpacing.pagePadding,
        16,
        MoodBloomSpacing.pagePadding,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Confirm purchase',
            style: MbFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: mb.text,
            ),
          ),
          const SizedBox(height: 16),
          // 120x120 preview window
          Center(
            child: _PreviewWindow(skinId: widget.skin.id, mb: mb),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '${widget.skin.displayName} skin',
              style: MbFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: mb.text,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              widget.skin.tagline,
              textAlign: TextAlign.center,
              style: MbFonts.nunito(fontSize: 13, color: mb.textDim),
            ),
          ),
          const SizedBox(height: 16),
          MbCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _CostRow(
                  label: 'Skin cost',
                  value: widget.skin.cost,
                  bold: true,
                ),
                Divider(height: 16, color: mb.line),
                _CostRow(
                  label: 'Current balance',
                  value: widget.currentBalance,
                ),
                const SizedBox(height: 8),
                _CostRow(label: 'After purchase', value: after, bold: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Skins apply to every plant in your garden. You can change skins '
            'anytime from settings.',
            style: MbFonts.nunito(fontSize: 12, color: mb.textDim, height: 1.5),
          ),
          const SizedBox(height: 16),
          MbPrimaryButton(
            label: 'Purchase & equip',
            leading: const Icon(Icons.check, size: 18, color: Colors.white),
            loading: _busy,
            onPressed: _busy ? null : _onPurchase,
          ),
          const SizedBox(height: 8),
          MbGhostButton(
            label: 'Maybe later',
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }

  Future<void> _onPurchase() async {
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final state =
        ref.read(skinStateStreamProvider).value ?? SkinState.initial();
    final useCase = ref.read(unlockGardenSkinUseCaseProvider);
    final result = await useCase(
      userId: user.uid,
      id: widget.skin.id,
      currentState: state,
      currentBalance: widget.currentBalance,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      ok: (_) {
        messenger.showSnackBar(
          SnackBar(content: Text('Equipped ${widget.skin.displayName}!')),
        );
        navigator.pop(true);
      },
      err: (failure) {
        final message = switch (failure) {
          SkinFailure() when failure.message.contains('Not enough tokens') =>
            failure.message,
          _ => "Couldn't unlock - please try again.",
        };
        messenger.showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }
}

class _PreviewWindow extends StatelessWidget {
  const _PreviewWindow({required this.skinId, required this.mb});

  final GardenSkinId skinId;
  final MbColors mb;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [mb.skyTop, mb.skyMid, mb.ground],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 30,
            child: Container(color: mb.ground2),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 6,
            child: Center(
              child: MbSkinPlant(
                skinId: skinId,
                mood: MbMoodKind.happy,
                intensity: 5,
                color: MoodBloomColors.moodHappy,
                size: const Size(40, 84),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({required this.label, required this.value, this.bold = false});

  final String label;
  final int value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Text(label, style: MbFonts.nunito(fontSize: 14, color: mb.textDim)),
          const Spacer(),
          MbTokenGlyphSvg(
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: MbFonts.nunito(
              fontSize: 14,
              color: mb.text,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
