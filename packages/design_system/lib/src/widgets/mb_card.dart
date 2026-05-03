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
    final resolvedDecoration =
        decoration ??
        BoxDecoration(
          color: mb.card,
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
          border: Border.all(color: mb.line),
        );
    final resolvedPadding = padding ?? const EdgeInsets.all(16);

    final content = Padding(padding: resolvedPadding, child: child);

    if (onTap == null) {
      return DecoratedBox(decoration: resolvedDecoration, child: content);
    }

    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: resolvedDecoration,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              (resolvedDecoration.borderRadius as BorderRadius?) ??
              BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
          child: content,
        ),
      ),
    );
  }
}
