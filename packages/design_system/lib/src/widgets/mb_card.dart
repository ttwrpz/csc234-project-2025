import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Surface container with the prototype's white card + 1px line border + r20.
///
/// Pass [decoration] to override the default look (e.g. for the AI suggestion
/// card which uses a tinted background); otherwise the card resolves the
/// `MbColors` extension from the theme.
class MbCard extends StatelessWidget {
  const MbCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.decoration,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final BoxDecoration? decoration;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final resolvedPadding = padding ?? const EdgeInsets.all(16);
    final content = Padding(padding: resolvedPadding, child: child);

    // Custom-decoration path — preserves the legacy behaviour for
    // callers that hand in a tinted/gradient background (e.g. the AI
    // suggestion card). Inner InkWells in those subtrees still render
    // splash behind the decoration, but those call sites are
    // non-interactive presentation cards (no ListTile taps), so the
    // legacy structure is fine for them.
    if (decoration != null) {
      if (onTap == null) {
        return DecoratedBox(decoration: decoration!, child: content);
      }
      return Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: decoration!,
          child: InkWell(
            onTap: onTap,
            borderRadius:
                (decoration!.borderRadius as BorderRadius?) ??
                BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
            child: content,
          ),
        ),
      );
    }

    // Default-decoration path — uses an opaque `Material(color: mb.card)`
    // as the outermost widget so descendant InkWells (ListTiles inside
    // Settings clusters, etc.) can paint visible splash + highlight ON
    // TOP of the card surface. v1.6 fix for "press effect renders
    // behind the background" — the prior structure put the splash
    // beneath the `Ink` decoration's paint layer (no-onTap → no
    // Material at all; with-onTap → MaterialType.transparency below
    // Ink), so inner taps had no visible feedback.
    final radius = BorderRadius.circular(MoodBloomSpacing.radiusCardLg);
    final shape = RoundedRectangleBorder(
      borderRadius: radius,
      side: BorderSide(color: mb.line),
    );
    return Material(
      color: mb.card,
      shape: shape,
      clipBehavior: clipBehavior,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: content,
            ),
    );
  }
}
