import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'mb_bottom_nav.dart' show MbBottomNavItem;

/// Width of the desktop sidebar. Matches the prototype's `app-desktop`
/// CSS grid template (240 px column, body content fills the remainder).
const double kMbSideNavWidth = 240;

/// Vertical sidebar used by the app shell at tablet/desktop widths.
///
/// Same item model as `MbBottomNav` so the router can pass one list to
/// either widget. Layout is a brand row at the top, a vertical list of
/// destinations, and a small footer caption at the bottom.
class MbSideNav extends StatelessWidget {
  const MbSideNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.brandLabel = 'MoodBloom',
    this.footer,
    this.actions = const <Widget>[],
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<MbBottomNavItem> items;
  final String brandLabel;

  /// Optional small caption rendered at the bottom of the sidebar
  /// (e.g. user name + sprint label).
  final String? footer;

  /// Account-level action widgets rendered above the [footer] caption.
  /// Used on desktop for the sign-out button + theme switcher (v1.0
  /// polish). Empty list (default) collapses the slot — phones / tablet
  /// shells that never compose this widget keep their original layout.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: mb.card,
        border: Border(right: BorderSide(color: mb.line, width: 1)),
      ),
      child: SizedBox(
        width: kMbSideNavWidth,
        child: SafeArea(
          right: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 20),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      brandLabel,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: mb.text,
                      ),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < items.length; i++)
                _MbSideNavTab(
                  item: items[i],
                  active: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              const Spacer(),
              if (actions.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: mb.line, height: 1),
                ),
                for (final action in actions) action,
              ],
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    footer!,
                    style: TextStyle(fontSize: 11, color: mb.textDim),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Public action tile reusable in [MbSideNav.actions]. Same visual
/// language as a non-active nav tab — icon + label, transparent
/// background, hover-tinted on focus. Optional [destructive] flag
/// applies the high-contrast `coralText` color from the design tokens.
class MbSideNavAction extends StatelessWidget {
  const MbSideNavAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final color = destructive ? mb.destructiveText : mb.text;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MbSideNavTab extends StatelessWidget {
  const _MbSideNavTab({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final MbBottomNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>()!;
    final color = active ? mb.text : mb.textDim;
    final bg = active ? mb.bg : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Semantics(
        button: true,
        selected: active,
        label: item.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(item.icon, size: 18, color: color),
                  const SizedBox(width: 10),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      color: color,
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
