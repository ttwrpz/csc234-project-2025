import 'mb_fonts.dart';
import 'package:flutter/material.dart';

import '../tokens/colors.dart';

/// One option inside an [MbSegmentedToggle].
@immutable
class MbSegmentedItem<T> {
  const MbSegmentedItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// Pill-shaped segmented control with a sliding active indicator. Used for
/// the History list/calendar swap, Analytics 7/30/90 windows, and
/// Settings dataset toggles in the prototype.
class MbSegmentedToggle<T> extends StatelessWidget {
  const MbSegmentedToggle({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.height = 40,
  }) : assert(items.length > 0, 'items must not be empty');

  final List<MbSegmentedItem<T>> items;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final theme = Theme.of(context);
    final selectedIndex = items.indexWhere((i) => i.value == value);
    final clampedIndex = selectedIndex < 0 ? 0 : selectedIndex;

    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = 3.0;
        final segWidth = (constraints.maxWidth - padding * 2) / items.length;

        return Container(
          height: height,
          padding: const EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: mb.bg,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: mb.line),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                left: segWidth * clampedIndex,
                top: 0,
                bottom: 0,
                width: segWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: InkWell(
                        onTap: () => onChanged(items[i].value),
                        borderRadius: BorderRadius.circular(height / 2),
                        child: Center(
                          child: Text(
                            items[i].label,
                            style: MbFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: i == clampedIndex
                                  ? Colors.white
                                  : mb.textDim,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
