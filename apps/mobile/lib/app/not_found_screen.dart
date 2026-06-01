import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Friendly 404 surface shown by GoRouter's `errorBuilder` when a route
/// (or a deep-link / typed web URL) does not match. Keeps the app's gentle
/// tone instead of a raw error page, and offers a single way back home.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, this.location});

  /// The unmatched path, shown quietly for orientation. Optional.
  final String? location;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Scaffold(
      backgroundColor: mb.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(MoodBloomSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.explore_off_outlined, size: 56, color: mb.textDim),
                  const SizedBox(height: 16),
                  Text(
                    "This path doesn't bloom here",
                    textAlign: TextAlign.center,
                    style: MbFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: mb.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "The page you were looking for isn't here. Let's head back "
                    'to your garden.',
                    textAlign: TextAlign.center,
                    style: MbFonts.nunito(
                      fontSize: 14,
                      height: 1.5,
                      color: mb.textDim,
                    ),
                  ),
                  if (location != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      location!,
                      textAlign: TextAlign.center,
                      style: MbFonts.nunito(
                        fontSize: 11,
                        color: mb.textDim.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  MbPrimaryButton(
                    label: 'Back to garden',
                    fullWidth: false,
                    onPressed: () => context.go('/home'),
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
