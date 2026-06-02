import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Presents [child] as a centred dialog on tablet/desktop and a
/// bottom sheet on phones. A full-width bottom sheet reads as broken on a
/// wide viewport, so anything that's a "sheet" on a phone (the identity
/// confirm / privacy-lock verify surfaces) routes through this instead.
///
/// The caller decides any presentation-specific chrome (e.g. whether to
/// draw a drag handle) by checking [isWideViewport] for the same context
/// before building [child].
Future<T?> showAdaptiveModal<T>(
  BuildContext context, {
  required Widget child,
  double maxWidth = 460,
}) {
  final mb = Theme.of(context).extension<MbColors>()!;
  final size = MediaQuery.of(context).size;

  if (isWideViewport(context)) {
    return showDialog<T>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: mb.bg,
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: size.height * 0.9,
          ),
          child: child,
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: mb.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(MoodBloomSpacing.radiusCardLg),
      ),
    ),
    builder: (_) => child,
  );
}

/// The tablet/desktop breakpoint used by [showAdaptiveModal] - mirrors the
/// `_tabletMin` used by the auth screens so the modal and the screen agree
/// on what "wide" means.
bool isWideViewport(BuildContext context) =>
    MediaQuery.of(context).size.width >= 600;
