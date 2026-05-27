import 'package:flutter/material.dart';

import '../tokens/breakpoints.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import 'mb_fonts.dart';
import 'mb_icon_button.dart';

/// Presents a modal surface the way the v1.6 prototype's `ModalFrame`
/// does: a bottom sheet on phone-class widths (`< MbBreakpoints.modalDialog`)
/// and a centered dialog on tablet/desktop.
///
///   * Phone   - bottom sheet, full width, top corners rounded 20 dp,
///               capped at 92% of viewport height, scrolls internally.
///   * Tablet+ - centered dialog, max 560 dp wide, capped at 86% of
///               viewport height, card-radius corners, 24 dp inset.
///
/// The [builder] supplies the modal body. Pair it with [MbModalScaffold]
/// to get the standard close-icon header + scrollable body.
abstract final class MbModalSheet {
  const MbModalSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isDismissible = true,
  }) {
    final isDialog =
        MediaQuery.sizeOf(context).width >= MbBreakpoints.modalDialog;
    final mb = Theme.of(context).extension<MbColors>()!;

    if (isDialog) {
      return showDialog<T>(
        context: context,
        barrierDismissible: isDismissible,
        builder: (ctx) {
          final h = MediaQuery.sizeOf(ctx).height;
          return Dialog(
            backgroundColor: mb.bg,
            clipBehavior: Clip.antiAlias,
            insetPadding: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                MoodBloomSpacing.radiusCardLg,
              ),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 560, maxHeight: h * 0.86),
              child: builder(ctx),
            ),
          );
        },
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      useSafeArea: true,
      backgroundColor: mb.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      builder: builder,
    );
  }
}

/// Standard modal body chrome: a fixed header row (close icon + serif
/// title) above a scrollable body. Sizes to its content (so a short
/// modal hugs its body) but caps at the enclosing [MbModalSheet]
/// constraints, scrolling the body when taller.
class MbModalScaffold extends StatelessWidget {
  const MbModalScaffold({
    super.key,
    required this.title,
    required this.onClose,
    required this.child,
    this.icon = Icons.close,
    this.scrollable = true,
    this.padding = const EdgeInsets.fromLTRB(18, 14, 18, 18),
  });

  /// Serif title shown next to the close icon.
  final String title;

  /// Invoked when the header icon is tapped. Callers pass
  /// `() => Navigator.of(context).pop()` (or a richer dismiss handler).
  final VoidCallback onClose;

  /// Header leading icon. Defaults to a close "x"; pass
  /// `Icons.arrow_back` for back-style modals.
  final IconData icon;

  /// Modal body. Rendered inside a scroll view when [scrollable].
  final Widget child;

  /// When true (default) the body scrolls inside the modal's height
  /// cap. Set false for bodies that manage their own scrolling or are
  /// known to fit (e.g. a fixed-height breathing animation).
  final bool scrollable;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final body = scrollable
        ? Flexible(child: SingleChildScrollView(child: child))
        : Flexible(child: child);
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _MbModalHeader(title: title, onClose: onClose, icon: icon),
          const SizedBox(height: 8),
          body,
        ],
      ),
    );
  }
}

class _MbModalHeader extends StatelessWidget {
  const _MbModalHeader({
    required this.title,
    required this.onClose,
    required this.icon,
  });

  final String title;
  final VoidCallback onClose;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: mb.line)),
      ),
      child: Row(
        children: <Widget>[
          MbIconButton(
            icon: Icon(icon),
            onPressed: onClose,
            size: MbIconButtonSize.sm,
            semanticLabel: 'Close',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: MbFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: mb.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
