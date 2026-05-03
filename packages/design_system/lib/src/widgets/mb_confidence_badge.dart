import 'mb_fonts.dart';
import 'package:flutter/material.dart';

/// Three confidence buckets used by the AI suggestion + pattern analysis
/// surfaces. The 'low' bucket is the gentlest visual.
enum MbConfidenceLevel { high, medium, low }

/// Pill that pairs a colored dot with a "[level] confidence" label
/// (e.g. "high confidence"). Color buckets
/// follow the prototype: high green / medium amber / low neutral, with dark
/// variants resolved automatically from the active brightness.
class MbConfidenceBadge extends StatelessWidget {
  const MbConfidenceBadge({super.key, required this.level});

  final MbConfidenceLevel level;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (Color bg, Color fg, Color dot) = switch (level) {
      MbConfidenceLevel.high =>
        isDark
            ? (
                const Color(0xFF1F3A2E),
                const Color(0xFFA9D9BD),
                const Color(0xFF63B689),
              )
            : (
                const Color(0xFFE8F3ED),
                const Color(0xFF1F5A41),
                const Color(0xFF2E7D5B),
              ),
      MbConfidenceLevel.medium =>
        isDark
            ? (
                const Color(0xFF3A2F1A),
                const Color(0xFFE8C77D),
                const Color(0xFFD9A23B),
              )
            : (
                const Color(0xFFFCF1DA),
                const Color(0xFF8B6F1E),
                const Color(0xFFE8A23B),
              ),
      MbConfidenceLevel.low =>
        isDark
            ? (
                const Color(0xFF2A323D),
                const Color(0xFFB0BCC9),
                const Color(0xFF8A98A7),
              )
            : (
                const Color(0xFFEFEFEC),
                const Color(0xFF606872),
                const Color(0xFF9AA3AE),
              ),
    };

    final label = switch (level) {
      MbConfidenceLevel.high => 'high confidence',
      MbConfidenceLevel.medium => 'medium confidence',
      MbConfidenceLevel.low => 'low confidence',
    };

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dot,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: MbFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
