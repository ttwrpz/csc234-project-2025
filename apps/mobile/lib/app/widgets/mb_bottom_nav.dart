import 'dart:ui';

import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Visual height of the [MbBottomNav] *content* (excluding system safe-area
/// padding). Callers should add `MediaQuery.viewPaddingOf(context).bottom`
/// to push body content above the home-indicator on devices that need it.
const double kMbBottomNavHeight = 70;

/// One destination on the [MbBottomNav] / [MbSideNav].
///
/// `icon` is a Material `IconData` so the glyph scales, themes, and renders
/// identically across platforms (the previous emoji glyphs varied
/// considerably between Android, iOS, and the various web font fallbacks).
///
/// When [highlighted] is true the item is rendered as a primary-tinted
/// circular button, drawing the eye to the most-frequent action (the Log
/// slot). Used at most once per nav.
@immutable
class MbBottomNavItem {
  const MbBottomNavItem({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;
}

/// Translucent bottom navigation bar used by the app shell on phone-width
/// layouts.
///
/// Background uses [MbColors.navBg] (an `0xE6...` ARGB value, ~90% opaque)
/// over a `BackdropFilter` blur so the cream/navy scaffold and any flora
/// behind it bleed through softly. A 1 px [MbColors.line] border sits on top.
///
/// Each tab is an `InkWell` with no splash highlight, sized to fill the row
/// evenly via `Expanded`. Active state shows the brand primary color and
/// 700-weight label; inactive icons render in [MbColors.textDim] at weight
/// 500.
class MbBottomNav extends StatelessWidget {
  const MbBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<MbBottomNavItem> items;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;

    // The bar content. The highlighted "Add" slot renders its circular
    // button inline, vertically centred with the other tabs, so it sits at
    // the same height as the rest of the bar instead of poking above it.
    final barContent = DecoratedBox(
      decoration: BoxDecoration(
        color: mb.navBg,
        border: Border(top: BorderSide(color: mb.line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: items[i].highlighted
                      ? _HighlightedFab(
                          item: items[i],
                          active: i == currentIndex,
                          primary: MoodBloomColors.seed,
                          onTap: () => onTap(i),
                        )
                      : _MbBottomNavTab(
                          item: items[i],
                          active: i == currentIndex,
                          primary: MoodBloomColors.seed,
                          textDim: mb.textDim,
                          onTap: () => onTap(i),
                        ),
                ),
            ],
          ),
        ),
      ),
    );

    // On web, CanvasKit allocates a live offscreen WebGL surface per
    // BackdropFilter and leaks them across hot restarts ("Too many active
    // WebGL contexts"). The nav fill (mb.navBg) is already ~90% opaque, so
    // the frosted blur adds little - skip it on web, keep it on native.
    final bar = kIsWeb
        ? barContent
        : ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: barContent,
            ),
          );

    return bar;
  }
}

class _MbBottomNavTab extends StatelessWidget {
  const _MbBottomNavTab({
    required this.item,
    required this.active,
    required this.primary,
    required this.textDim,
    required this.onTap,
  });

  final MbBottomNavItem item;
  final bool active;
  final Color primary;
  final Color textDim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? primary : textDim;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 22, color: color),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary-tinted circular button used for the centred Log slot. Rendered
/// inline in the nav row, vertically centred with the other tabs so it sits
/// at the same height as the bar rather than poking above it, while the
/// circular fill still marks it as the main action.
///
/// 46×46 circle, `MoodBloomColors.seed` fill, white `Icons.add` 24 dp glyph,
/// soft seed-tinted drop-shadow for a touch of elevation. `Material` +
/// `InkWell` give a circular ripple.
class _HighlightedFab extends StatelessWidget {
  const _HighlightedFab({
    required this.item,
    required this.active,
    required this.primary,
    required this.onTap,
  });

  final MbBottomNavItem item;
  final bool active;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      child: Center(
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Icon(item.icon, size: 24, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
