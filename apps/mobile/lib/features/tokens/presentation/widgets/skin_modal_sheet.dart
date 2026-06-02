import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Legacy "open skin customization" entry point. Under the v1.6 global
/// skin model the rich customization surface lives at the dedicated
/// `/garden/skins` route (the Skin Shop screen). This shim is kept so
/// callers that still reach for `SkinModalSheet.show(context)` don't
/// have to be hunted down all at once - they just punt to the new
/// route.
///
/// The Phase 12 brief calls this out as "gut and rewrite as a redirect
/// to the new Skin Shop screen". Once Phase 13's test migration is
/// done and the call-sites are updated to `context.go('/garden/skins')`
/// directly, this file can be deleted entirely.
class SkinModalSheet {
  const SkinModalSheet._();

  /// Navigates to `/garden/skins`. Async signature is preserved for
  /// compatibility with the old `showModalBottomSheet` call. Uses push so
  /// a system back pops the shop instead of exiting the app.
  static Future<void> show(BuildContext context) async {
    context.push('/garden/skins');
  }
}
