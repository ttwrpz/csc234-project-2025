import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Layout variant for an [OnboardingSlide]. Picked by the parent screen
/// from the active viewport width - phone stacks vertically, tablet
/// and desktop use a two-column row (art on the left, copy on the right).
enum OnboardingLayout { phone, tablet, desktop }

/// One page of the onboarding carousel. Shows a small inline brand
/// illustration alongside a Fraunces 600 title and a Nunito dim body.
///
///  * `phone`   - vertical stack, title 26 sp.
///  * `tablet`  - two-column row (art flex 6, copy flex 4), title 28 sp,
///                left-aligned copy.
///  * `desktop` - two-column row, 50/50, title 30 sp, left-aligned copy.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    super.key,
    required this.art,
    required this.title,
    required this.body,
    this.layout = OnboardingLayout.phone,
  });

  final Widget art;
  final String title;
  final String body;
  final OnboardingLayout layout;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final isPhone = layout == OnboardingLayout.phone;
    final titleStyle = MbFonts.fraunces(
      fontSize: isPhone ? 26 : (layout == OnboardingLayout.desktop ? 30 : 28),
      fontWeight: FontWeight.w600,
      color: mb.text,
    );
    final bodyStyle = MbFonts.nunito(
      fontSize: 16,
      height: 1.55,
      color: mb.textDim,
    );

    final titleText = Text(
      title,
      style: titleStyle,
      textAlign: isPhone ? TextAlign.center : TextAlign.start,
    );
    final bodyText = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Text(
        body,
        style: bodyStyle,
        textAlign: isPhone ? TextAlign.center : TextAlign.start,
      ),
    );

    final padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 24);
    return Semantics(
      label: title,
      child: Padding(
        padding: padding,
        child: switch (layout) {
          OnboardingLayout.phone => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              art,
              const SizedBox(height: 24),
              titleText,
              const SizedBox(height: 12),
              bodyText,
            ],
          ),
          OnboardingLayout.tablet => Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 6, child: Center(child: art)),
              const SizedBox(width: 24),
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titleText, const SizedBox(height: 12), bodyText],
                ),
              ),
            ],
          ),
          OnboardingLayout.desktop => Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Center(child: art)),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titleText, const SizedBox(height: 14), bodyText],
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}
