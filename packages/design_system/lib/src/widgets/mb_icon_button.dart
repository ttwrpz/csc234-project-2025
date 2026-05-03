import 'package:flutter/material.dart';

import '../tokens/colors.dart';

/// Two sizes for the prototype's tap-target icon buttons.
enum MbIconButtonSize { sm, md }

/// Square icon button. Card bg, 1px line border, r12. Used for chevrons,
/// back arrows, and segmented sub-controls.
class MbIconButton extends StatelessWidget {
  const MbIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = MbIconButtonSize.md,
    this.semanticLabel,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final MbIconButtonSize size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final dim = size == MbIconButtonSize.md ? 36.0 : 28.0;
    final button = Material(
      color: mb.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: mb.line),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: dim,
          width: dim,
          child: IconTheme.merge(
            data: IconThemeData(color: mb.text, size: dim * 0.5),
            child: Center(child: icon),
          ),
        ),
      ),
    );
    if (semanticLabel == null) return button;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ExcludeSemantics(child: button),
    );
  }
}
