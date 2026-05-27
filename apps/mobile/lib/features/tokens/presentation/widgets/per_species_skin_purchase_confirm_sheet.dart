import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/providers.dart';
import '../../../garden/domain/entities/flower_species.dart';
import '../../data/providers.dart';
import '../../domain/entities/per_species_skin.dart';
import '../../domain/entities/per_species_skin_state.dart';
import '../../domain/skin_failure.dart';

/// Modal confirmation sheet for buying + equipping a PER-SPECIES flower
/// skin. Mirrors [SkinPurchaseConfirmSheet] (the global confirm) but the
/// copy makes clear the skin recolours only ONE flower, not the whole
/// garden, and the preview paints that species' classic bloom in the
/// skin's accent colour.
class PerSpeciesSkinPurchaseConfirmSheet extends ConsumerStatefulWidget {
  const PerSpeciesSkinPurchaseConfirmSheet({
    super.key,
    required this.skin,
    required this.currentBalance,
  });

  final PerSpeciesSkin skin;
  final int currentBalance;

  /// Responsive launcher - bottom sheet on phone, centered dialog on
  /// tablet+. Resolves to `true` on a successful purchase, `false`
  /// otherwise (cancellation, error, or unmounted).
  static Future<bool> show(
    BuildContext context, {
    required PerSpeciesSkin skin,
    required int currentBalance,
  }) async {
    final size = MediaQuery.sizeOf(context);
    if (size.width < MbBreakpoints.modalDialog) {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PerSpeciesSkinPurchaseConfirmSheet(
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
          child: PerSpeciesSkinPurchaseConfirmSheet(
            skin: skin,
            currentBalance: currentBalance,
          ),
        ),
      ),
    );
    return ok ?? false;
  }

  @override
  ConsumerState<PerSpeciesSkinPurchaseConfirmSheet> createState() =>
      _PerSpeciesSkinPurchaseConfirmSheetState();
}

class _PerSpeciesSkinPurchaseConfirmSheetState
    extends ConsumerState<PerSpeciesSkinPurchaseConfirmSheet> {
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
          Center(
            child: _PreviewWindow(skin: widget.skin, mb: mb),
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
            'This skin recolours just this one flower, layered over your '
            'garden skin. You can switch back to the default anytime.',
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
        ref.read(perSpeciesSkinStateStreamProvider).value ??
        PerSpeciesSkinState.initial();
    final useCase = ref.read(unlockPerSpeciesSkinUseCaseProvider);
    final result = await useCase(
      userId: user.uid,
      skin: widget.skin,
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
  const _PreviewWindow({required this.skin, required this.mb});

  final PerSpeciesSkin skin;
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
            bottom: 10,
            child: Center(
              child: MbSkinPlant(
                skinId: skin.style,
                mood: _moodOfSpecies(skin.species),
                intensity: 4,
                color: Color(skin.accentArgb),
                size: const Size(46, 96),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Species -> the mood it represents, so the confirm preview renders the
/// right `MbSkinPlant` bloom in the skin's shape style.
MbMoodKind _moodOfSpecies(FlowerSpecies species) => switch (species) {
  FlowerSpecies.sunflower => MbMoodKind.happy,
  FlowerSpecies.lavender => MbMoodKind.calm,
  FlowerSpecies.daisy => MbMoodKind.okay,
  FlowerSpecies.poppy => MbMoodKind.angry,
  FlowerSpecies.fern => MbMoodKind.anxious,
  FlowerSpecies.forgetMeNot => MbMoodKind.sad,
};

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
