import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/data/providers.dart';
import '../../../garden/domain/entities/plant_tier.dart';
import '../../../garden/data/providers.dart';
import '../../data/providers.dart';
import '../../domain/entities/garden_skin.dart';
import '../../domain/entities/skin_state.dart';
import '../../domain/services/garden_skin_catalog.dart';
import '../widgets/skin_purchase_confirm_sheet.dart';

/// User-facing screen for browsing + purchasing global garden skins.
///
/// Layout per `skin-shop.jsx`:
///   * Header: "Customize your garden" + subtitle + token balance pill.
///   * Equipped card: soft-green hero with 80x80 preview + 6 mood plants
///     mini-row + skin name + tagline.
///   * Skin library grid: 1 / 2 / 3 columns at phone / tablet / desktop.
///     Each card has a 3-plant preview window, name, price badge,
///     tagline (or lock reason), and an action button.
///   * Disclaimer footer.
///
/// Reachable from Settings -> GARDEN -> "Customize your garden" tile.
class SkinShopScreen extends ConsumerWidget {
  const SkinShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final state =
        ref.watch(skinStateStreamProvider).value ?? SkinState.initial();
    final balance = ref.watch(tokenBalanceStreamProvider).value?.balance ?? 0;
    final gardenAsync = ref.watch(gardenStateStreamProvider);
    final tier = gardenAsync.value?.plantTier ?? PlantTier.resting;
    final hasFlourishing = tier == PlantTier.flourishing;

    return Scaffold(
      backgroundColor: mb.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/settings');
            }
          },
        ),
        backgroundColor: mb.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Skin Shop',
          style: MbFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: mb.text,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cols = w >= MbBreakpoints.desktop
                ? 3
                : w >= MbBreakpoints.modalDialog
                ? 2
                : 1;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                MoodBloomSpacing.pagePadding,
                12,
                MoodBloomSpacing.pagePadding,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _Header(balance: balance, mb: mb),
                  const SizedBox(height: 18),
                  _EquippedCard(equippedId: state.equippedSkinId, mb: mb),
                  const SizedBox(height: 18),
                  const MbSectionLabel('SKIN LIBRARY'),
                  const SizedBox(height: 10),
                  _SkinLibraryGrid(
                    cols: cols,
                    state: state,
                    balance: balance,
                    hasFlourishing: hasFlourishing,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Skins are cosmetic only. Your entries and history are '
                    'never affected.',
                    style: MbFonts.nunito(
                      fontSize: 11,
                      color: mb.textDim,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.balance, required this.mb});

  final int balance;
  final MbColors mb;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Customize your garden',
                style: MbFonts.fraunces(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: mb.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tokens are earned for showing up. Pick a skin to reshape '
                'every plant in your garden.',
                style: MbFonts.nunito(
                  fontSize: 13,
                  color: mb.textDim,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        _BalancePill(balance: balance, mb: mb),
      ],
    );
  }
}

class _BalancePill extends StatelessWidget {
  const _BalancePill({required this.balance, required this.mb});

  final int balance;
  final MbColors mb;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: mb.card,
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusFull),
        border: Border.all(color: mb.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MbTokenGlyphSvg(size: 18, color: primary),
          const SizedBox(width: 8),
          Text(
            '$balance',
            style: MbFonts.fraunces(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: mb.text,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'TOKENS',
            style: MbFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: mb.textDim,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _EquippedCard extends StatelessWidget {
  const _EquippedCard({required this.equippedId, required this.mb});

  final GardenSkinId equippedId;
  final MbColors mb;

  @override
  Widget build(BuildContext context) {
    final skin = GardenSkinCatalog.byId(equippedId);
    final seedDark = MoodBloomColors.seedDark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MoodBloomColors.softGreen,
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: <Widget>[
          // 80x80 preview window
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: mb.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: mb.line),
            ),
            alignment: Alignment.bottomCenter,
            child: MbSkinPlant(
              skinId: equippedId,
              mood: MbMoodKind.happy,
              intensity: 5,
              color: MoodBloomColors.moodHappy,
              size: const Size(48, 64),
            ),
          ),
          // Name + tagline column
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 160, maxWidth: 260),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'EQUIPPED',
                  style: MbFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: seedDark,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  skin.displayName,
                  style: MbFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: seedDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  skin.tagline,
                  style: MbFonts.nunito(
                    fontSize: 13,
                    color: seedDark.withValues(alpha: 0.78),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // 6 mood mini row
          _MoodPreviewRow(skinId: equippedId),
        ],
      ),
    );
  }
}

class _MoodPreviewRow extends StatelessWidget {
  const _MoodPreviewRow({required this.skinId});

  final GardenSkinId skinId;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MbMoodPalette>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (final mood in MbMoodKind.values) ...[
            MbSkinPlant(
              skinId: skinId,
              mood: mood,
              intensity: 4,
              color: palette.colorOf(mood),
              size: const Size(22, 36),
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _SkinLibraryGrid extends StatelessWidget {
  const _SkinLibraryGrid({
    required this.cols,
    required this.state,
    required this.balance,
    required this.hasFlourishing,
  });

  final int cols;
  final SkinState state;
  final int balance;
  final bool hasFlourishing;

  @override
  Widget build(BuildContext context) {
    final all = GardenSkinCatalog.all;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 14.0;
        final cellWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final skin in all)
              SizedBox(
                width: cellWidth,
                child: _SkinCard(
                  skin: skin,
                  state: state,
                  balance: balance,
                  hasFlourishing: hasFlourishing,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SkinCard extends ConsumerStatefulWidget {
  const _SkinCard({
    required this.skin,
    required this.state,
    required this.balance,
    required this.hasFlourishing,
  });

  final GardenSkin skin;
  final SkinState state;
  final int balance;
  final bool hasFlourishing;

  @override
  ConsumerState<_SkinCard> createState() => _SkinCardState();
}

class _SkinCardState extends ConsumerState<_SkinCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final equipped = widget.state.equippedSkinId == widget.skin.id;
    final owned = widget.state.isUnlocked(widget.skin.id);
    final locked =
        widget.skin.requiresFlourishingTier && !widget.hasFlourishing && !owned;
    final affordable = widget.balance >= widget.skin.cost;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mb.card,
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
        border: Border.all(color: equipped ? primary : mb.line),
      ),
      child: Opacity(
        opacity: locked ? 0.85 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _SkinCardPreview(skinId: widget.skin.id, mb: mb, locked: locked),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.skin.displayName,
                    style: MbFonts.fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: mb.text,
                    ),
                  ),
                ),
                if (widget.skin.cost > 0 && !owned && !locked)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      MbTokenGlyphSvg(size: 13, color: primary),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.skin.cost}',
                        style: MbFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: mb.text,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 32),
              child: Text(
                locked
                    ? 'Reach the Flourishing tier to unlock.'
                    : widget.skin.tagline,
                style: MbFonts.nunito(
                  fontSize: 12,
                  color: mb.textDim,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _action(
              equipped: equipped,
              owned: owned,
              locked: locked,
              affordable: affordable,
              mb: mb,
              primary: primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _action({
    required bool equipped,
    required bool owned,
    required bool locked,
    required bool affordable,
    required MbColors mb,
    required Color primary,
  }) {
    if (equipped) {
      return Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: MoodBloomColors.softGreen,
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusButton),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.check_circle,
              size: 16,
              color: MoodBloomColors.seedDark,
            ),
            const SizedBox(width: 6),
            Text(
              'Equipped',
              style: MbFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: MoodBloomColors.seedDark,
              ),
            ),
          ],
        ),
      );
    }
    if (owned) {
      return MbGhostButton(label: 'Equip', onPressed: _busy ? null : _onEquip);
    }
    if (locked) {
      return MbGhostButton(label: 'Keep growing', onPressed: null);
    }
    if (affordable) {
      return MbPrimaryButton(
        label: 'Purchase',
        leading: const Icon(
          Icons.shopping_bag_outlined,
          size: 16,
          color: Colors.white,
        ),
        loading: _busy,
        onPressed: _busy ? null : _onPurchase,
      );
    }
    return MbGhostButton(label: 'Need more tokens', onPressed: null);
  }

  Future<void> _onEquip() async {
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(skinRepositoryProvider);
    final result = await repo.equip(userId: user.uid, id: widget.skin.id);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      ok: (_) {
        messenger.showSnackBar(
          SnackBar(content: Text('Equipped ${widget.skin.displayName}.')),
        );
      },
      err: (f) => messenger.showSnackBar(SnackBar(content: Text(f.message))),
    );
  }

  Future<void> _onPurchase() async {
    final ok = await SkinPurchaseConfirmSheet.show(
      context,
      skin: widget.skin,
      currentBalance: widget.balance,
    );
    if (!mounted) return;
    // Snackbar already shown inside the sheet. Nothing else to do here.
    // `ok` is true on success; either way the skinStateStreamProvider
    // rebuild flows back into this card naturally.
    if (!ok) return;
  }
}

class _SkinCardPreview extends StatelessWidget {
  const _SkinCardPreview({
    required this.skinId,
    required this.mb,
    required this.locked,
  });

  final GardenSkinId skinId;
  final MbColors mb;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MbMoodPalette>()!;
    return Container(
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [mb.skyTop, mb.skyMid, mb.ground],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          // Mini ground band
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 32,
            child: Container(color: mb.ground2),
          ),
          // 3 preview plants (happy / calm / okay) on the ground line
          Positioned(
            left: 0,
            right: 0,
            bottom: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (final mood in const [
                  MbMoodKind.happy,
                  MbMoodKind.calm,
                  MbMoodKind.okay,
                ])
                  MbSkinPlant(
                    skinId: skinId,
                    mood: mood,
                    intensity: 4,
                    color: palette.colorOf(mood),
                    size: const Size(28, 58),
                  ),
              ],
            ),
          ),
          if (locked)
            Positioned.fill(
              child: Container(
                color: const Color(0xFF1F2937).withValues(alpha: 0.55),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Locked',
                      style: MbFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
