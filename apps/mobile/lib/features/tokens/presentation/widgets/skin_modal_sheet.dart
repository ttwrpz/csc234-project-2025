import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/providers.dart';
import '../../../garden/domain/entities/flower_species.dart';
import '../../../garden/presentation/widgets/flower_sprite.dart';
import '../../data/providers.dart';
import '../../domain/entities/flower_skin.dart';
import '../../domain/entities/skin_state.dart';
import '../../domain/services/skin_catalog.dart';
import '../../domain/skin_failure.dart';
import 'locked_skin_chip.dart';
import 'spend_confirmation_dialog.dart';
import 'token_balance_chip.dart';

/// Bottom-sheet modal for flower-skin customization.
///
/// Layout (top to bottom):
///   1. Header — "Customize flowers" title + a [TokenBalanceChip]
///      mirroring the garden chip so the user always sees their
///      live balance while shopping.
///   2. Per-species grid section — six sections (one per species),
///      each rendering the species' catalog in a horizontally-
///      scrollable row of skin cards. Each card shows the skin's
///      [FlowerSprite] preview, displayName, and one of:
///        * `Selected` chip — if this skin is the active selection.
///        * `Owned` button — owned but not selected; tap to activate.
///        * [LockedSkinChip] with cost — not yet purchased; tap to
///          open the spend confirmation dialog.
///   3. Footer disclaimer — single muted line reminding the user
///      that skins are cosmetic only.
///
/// State sources:
///   * `skinStateStreamProvider` — user's pool + selection.
///   * `tokenBalanceStreamProvider` — for affordable/unaffordable
///     visual state on locked chips.
///   * Both providers refresh after a successful unlock so the chip
///     pre-pop balance updates without an explicit `setState`.
class SkinModalSheet extends ConsumerWidget {
  const SkinModalSheet({super.key});

  /// Stable key on the ConstrainedBox that caps the centered-dialog
  /// width. Exposed so widget tests can assert the chosen breakpoint
  /// without false-positives from Dialog's internal sizing layers.
  @visibleForTesting
  static const Key dialogConstraintsKey = ValueKey(
    'skinModalSheet.dialogConstraints',
  );

  /// Breakpoints mirror `_AppShell._tabletMin` / `_desktopMin` in
  /// `apps/mobile/lib/app/router.dart`. Keep these aligned with the
  /// shell so the chrome we pick here matches the navigation layout
  /// at the same viewport width.
  static const double _tabletMin = 600;
  static const double _desktopMin = 900;

  /// Dialog max-width on desktop. The skin modal renders a 6-row grid of
  /// 132 dp cards with a horizontal scroller per row — 640 dp comfortably
  /// fits ~4.5 cards in view without forcing the user to scroll on a
  /// fresh tap. Wider just adds empty space because each row clips at the
  /// `ListView.separated` boundary anyway.
  static const double _desktopDialogMaxWidth = 640;

  /// Dialog max-width on tablet. 560 dp matches the spend-confirmation
  /// dialog's natural action-row width and shows ~4 cards before the
  /// horizontal scroller picks up.
  static const double _tabletDialogMaxWidth = 560;

  /// Cap the dialog at 80% of the viewport height so the home page
  /// underneath stays peeking through — the same compositional cue the
  /// phone bottom-sheet's `DraggableScrollableSheet.initialChildSize`
  /// gives at 0.85.
  static const double _dialogMaxHeightFraction = 0.8;

  /// Responsive launcher — bottom sheet on phone, centered dialog on
  /// tablet + desktop. Picks presentation off `MediaQuery.sizeOf` at the
  /// call site so a window-resize from desktop → phone width before the
  /// tap closes is still respected.
  static Future<void> show(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width < _tabletMin) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const SkinModalSheet(),
      );
    }
    final dialogMaxWidth = size.width >= _desktopMin
        ? _desktopDialogMaxWidth
        : _tabletDialogMaxWidth;
    final dialogMaxHeight = size.height * _dialogMaxHeightFraction;
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        clipBehavior: Clip.antiAlias,
        // Round the dialog edges with the same radius the bottom-sheet
        // uses on its top corners so the two presentations share a
        // family resemblance.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusSky),
        ),
        child: ConstrainedBox(
          // Key lets widget tests assert on the chosen breakpoint
          // without false-positives from Dialog's internal
          // ConstrainedBox layers (Material's min-width clamp etc.).
          key: dialogConstraintsKey,
          constraints: BoxConstraints(
            maxWidth: dialogMaxWidth,
            maxHeight: dialogMaxHeight,
          ),
          child: const SkinModalSheet(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final state = ref.watch(skinStateStreamProvider).value ?? SkinState.empty();
    final balance = ref.watch(tokenBalanceStreamProvider).value?.balance ?? 0;
    // The drag-handle is meaningful only in the bottom-sheet
    // presentation. When the launcher promotes us into a centered
    // dialog, the pill becomes a meaningless decoration — hide it so
    // the dialog reads like a focused panel, not a misplaced sheet.
    final isPhoneWidth = MediaQuery.sizeOf(context).width < _tabletMin;

    return Padding(
      // Lift the sheet above the keyboard if it ever opens (e.g. a
      // future "rename skin" path). Today the modal has no inputs but
      // the bottom-sheet idiom still benefits from the inset bottom.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: isPhoneWidth
          ? DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (_, scrollController) => _body(
                mb: mb,
                state: state,
                balance: balance,
                scrollController: scrollController,
                showHandle: true,
                roundTopOnly: true,
              ),
            )
          : _body(
              mb: mb,
              state: state,
              balance: balance,
              scrollController: null,
              showHandle: false,
              roundTopOnly: false,
            ),
    );
  }

  /// Body shared between the phone bottom-sheet and the tablet/desktop
  /// dialog. The only differences are (a) whether we round only the top
  /// edge (sheet) or none (dialog — its `Dialog` parent already clips
  /// with a uniform radius), (b) whether the drag-handle pill is shown,
  /// and (c) whether the `ListView` uses an externally-supplied scroll
  /// controller from `DraggableScrollableSheet`.
  Widget _body({
    required MbColors mb,
    required SkinState state,
    required int balance,
    required ScrollController? scrollController,
    required bool showHandle,
    required bool roundTopOnly,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: mb.bg,
        borderRadius: roundTopOnly
            ? const BorderRadius.vertical(
                top: Radius.circular(MoodBloomSpacing.radiusSky),
              )
            : null,
      ),
      child: Column(
        children: [
          if (showHandle) _Handle(),
          _Header(balance: balance),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: MoodBloomSpacing.pagePadding,
                vertical: MoodBloomSpacing.md,
              ),
              children: [
                for (final species in FlowerSpecies.values)
                  _SpeciesSection(
                    species: species,
                    state: state,
                    balance: balance,
                  ),
                const SizedBox(height: 12),
                const _CosmeticFooter(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: mb.textDim.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.balance});
  final int balance;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MoodBloomSpacing.pagePadding,
        4,
        MoodBloomSpacing.pagePadding,
        MoodBloomSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customize flowers',
                  style: MbFonts.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: mb.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Choose a look for each species.',
                  style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
                ),
              ],
            ),
          ),
          TokenBalanceChip(balance: balance),
        ],
      ),
    );
  }
}

class _CosmeticFooter extends StatelessWidget {
  const _CosmeticFooter();

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Text(
      // CLAUDE.md / spec §5 — skins never gate therapeutic features.
      // Footer makes the cosmetic-only invariant visible to the user.
      'Skins are cosmetic only. They never change how MoodBloom '
      'cares for you.',
      style: MbFonts.nunito(fontSize: 11, color: mb.textDim),
      textAlign: TextAlign.center,
    );
  }
}

/// One horizontally-scrollable row of skin cards for a single species.
class _SpeciesSection extends ConsumerWidget {
  const _SpeciesSection({
    required this.species,
    required this.state,
    required this.balance,
  });

  final FlowerSpecies species;
  final SkinState state;
  final int balance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final skins = SkinCatalog.forSpecies(species);
    final selectedId = state.selectedFor(species);
    // Default is treated as selected when no explicit selection has
    // been made (TC-10) — the species default is always available.
    final defaultSkin = SkinCatalog.defaultFor(species);
    final effectiveSelectedId = selectedId ?? defaultSkin.skinId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Text(
              _humanSpeciesName(species),
              style: MbFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: mb.text,
                letterSpacing: 0.4,
              ),
            ),
          ),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 2),
              itemCount: skins.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final skin = skins[index];
                return _SkinCard(
                  skin: skin,
                  isOwned:
                      skin.isDefault ||
                      state.isUnlocked(skin.species, skin.skinId),
                  isSelected: skin.skinId == effectiveSelectedId,
                  userBalance: balance,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _humanSpeciesName(FlowerSpecies s) => switch (s) {
    FlowerSpecies.sunflower => 'SUNFLOWER',
    FlowerSpecies.forgetMeNot => 'FORGET-ME-NOT',
    FlowerSpecies.daisy => 'DAISY',
    FlowerSpecies.poppy => 'POPPY',
    FlowerSpecies.fern => 'FERN',
    FlowerSpecies.lavender => 'LAVENDER',
  };
}

/// A single skin card. Three visual modes:
///   * selected → primary border + filled "Selected" pill.
///   * owned-not-selected → muted border + "Select" CTA.
///   * locked → muted border + [LockedSkinChip] cost + tap opens
///     [SpendConfirmationDialog]. Disabled-looking when unaffordable
///     (still tappable so the user can see the same confirmation
///     dialog — but the confirm action surfaces an "insufficient" snack).
class _SkinCard extends ConsumerStatefulWidget {
  const _SkinCard({
    required this.skin,
    required this.isOwned,
    required this.isSelected,
    required this.userBalance,
  });

  final FlowerSkin skin;
  final bool isOwned;
  final bool isSelected;
  final int userBalance;

  @override
  ConsumerState<_SkinCard> createState() => _SkinCardState();
}

class _SkinCardState extends ConsumerState<_SkinCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    final primary = theme.colorScheme.primary;
    final affordable = widget.isOwned || widget.userBalance >= widget.skin.cost;
    final borderColor = widget.isSelected
        ? primary
        : mb.textDim.withValues(alpha: 0.20);
    final bgColor = widget.isSelected
        ? primary.withValues(alpha: 0.06)
        : mb.card;

    // Tint the preview using a deterministic colour derived from the
    // skin's paletteSeed so alternates look visually distinct without
    // the painter knowing about every individual skin.
    final tint = _tintFor(widget.skin, theme);

    return Semantics(
      label: _semanticsLabel(),
      button: true,
      selected: widget.isSelected,
      child: ExcludeSemantics(
        child: SizedBox(
          width: 132,
          child: Material(
            color: bgColor,
            borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusLg),
            child: InkWell(
              borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusLg),
              onTap: _busy ? null : _onTap,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    MoodBloomSpacing.radiusLg,
                  ),
                  border: Border.all(
                    color: borderColor,
                    width: widget.isSelected ? 1.6 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: FlowerSprite(
                          species: widget.skin.species,
                          size: 44,
                          tint: tint,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.skin.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: MbFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: mb.text,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _trailing(affordable: affordable, primary: primary, mb: mb),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _trailing({
    required bool affordable,
    required Color primary,
    required MbColors mb,
  }) {
    if (widget.isSelected) {
      return _SelectedPill();
    }
    if (widget.isOwned) {
      return Text(
        'Tap to select',
        style: MbFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
      );
    }
    // Locked
    return Align(
      alignment: Alignment.centerLeft,
      child: LockedSkinChip(
        cost: widget.skin.cost,
        affordable: affordable,
        userBalance: widget.userBalance,
      ),
    );
  }

  /// Tap router:
  ///   * Selected → no-op (visual confirmation only).
  ///   * Owned-not-selected → call `SkinRepository.select` immediately
  ///     (no confirmation — re-selecting an owned skin is free).
  ///   * Locked, affordable → spend confirmation dialog.
  ///   * Locked, unaffordable → still show the dialog but surface a
  ///     "not enough tokens" snackbar (the in-transaction guard will
  ///     also reject; this is the cheaper client-side check).
  Future<void> _onTap() async {
    if (widget.isSelected) return;
    if (widget.isOwned) {
      await _select();
      return;
    }
    await _unlock();
  }

  Future<void> _select() async {
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(skinRepositoryProvider);
    final result = await repo.select(
      userId: user.uid,
      species: widget.skin.species,
      skinId: widget.skin.skinId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      ok: (_) {
        messenger.showSnackBar(
          SnackBar(content: Text('Selected ${widget.skin.displayName}.')),
        );
      },
      err: (f) => messenger.showSnackBar(SnackBar(content: Text(f.message))),
    );
  }

  Future<void> _unlock() async {
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) return;
    final affordable = widget.userBalance >= widget.skin.cost;
    if (!affordable) {
      // Show the same confirmation dialog so the user sees the price,
      // but pre-empt the spend with an explanatory snackbar. The
      // server-side guard would also reject; this avoids a confusing
      // "Confirm → silent failure" round-trip.
      final confirmed = await SpendConfirmationDialog.show(
        context,
        cost: widget.skin.cost,
        skinName: widget.skin.displayName,
      );
      if (!mounted) return;
      if (!confirmed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You have ${widget.userBalance} tokens - '
            '${widget.skin.cost - widget.userBalance} short.',
          ),
        ),
      );
      return;
    }

    final confirmed = await SpendConfirmationDialog.show(
      context,
      cost: widget.skin.cost,
      skinName: widget.skin.displayName,
    );
    if (!mounted) return;
    if (!confirmed) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final useCase = ref.read(unlockFlowerSkinUseCaseProvider);
    final state = ref.read(skinStateStreamProvider).value ?? SkinState.empty();
    final result = await useCase(
      userId: user.uid,
      skin: widget.skin,
      currentState: state,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      ok: (_) {
        messenger.showSnackBar(
          SnackBar(content: Text('Unlocked ${widget.skin.displayName}!')),
        );
      },
      err: (failure) {
        final message = switch (failure) {
          // Pull a clearer phrasing for the most common path.
          SkinFailure() when failure.message.contains('Not enough tokens') =>
            failure.message,
          _ => "Couldn't unlock - please try again.",
        };
        messenger.showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  String _semanticsLabel() {
    final skin = widget.skin;
    if (widget.isSelected) {
      return '${skin.displayName}, currently selected';
    }
    if (widget.isOwned) {
      return '${skin.displayName}, owned, double tap to select';
    }
    return '${skin.displayName}, locked, costs ${skin.cost} tokens, '
        'double tap to unlock';
  }

  /// Deterministic preview tint derived from the skin's paletteSeed.
  /// The default skin keeps the species' design-system mood swatch
  /// (handled by passing `null`-equivalent through the species default
  /// path). Alternates rotate a small palette of accent colours so the
  /// grid reads as varied without the data layer carrying a Color.
  static Color _tintFor(FlowerSkin skin, ThemeData theme) {
    if (skin.isDefault) {
      // Let FlowerSprite use its default species-mood tint.
      return theme.colorScheme.primary;
    }
    // Cycle through a small set of accent colours seeded by paletteSeed.
    const accents = <Color>[
      Color(0xFFD96E5C), // coral
      Color(0xFFE8A23B), // amber
      Color(0xFF7CA8D6), // muted blue
      Color(0xFFA493C8), // lavender
      Color(0xFF5C9A78), // moss
      Color(0xFFE6A4B4), // dusty pink
    ];
    return accents[skin.paletteSeed % accents.length];
  }
}

class _SelectedPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // v1.6 — M3's primaryContainer↔onPrimaryContainer pair guarantees
    // ≥4.5:1 in both light and dark, so the pill stays legible without
    // per-theme tuning. Previous primary-on-primary-with-alpha was
    // marginal in dark mode where primary lightens.
    final bg = theme.colorScheme.primaryContainer;
    final fg = theme.colorScheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            'Selected',
            style: MbFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
