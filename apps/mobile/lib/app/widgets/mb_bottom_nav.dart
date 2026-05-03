import 'dart:ui';

import 'package:design_system/design_system.dart';
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
@immutable
class MbBottomNavItem {
  const MbBottomNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
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
    final primary = Theme.of(context).colorScheme.primary;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: mb.navBg,
            border: Border(top: BorderSide(color: mb.line, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _MbBottomNavTab(
                        item: items[i],
                        active: i == currentIndex,
                        primary: primary,
                        textDim: mb.textDim,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
