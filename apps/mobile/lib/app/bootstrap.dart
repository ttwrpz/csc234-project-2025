import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/presentation/controllers/theme_mode_controller.dart';
import 'intervention_banner_host.dart';
import 'router.dart';
import 'theme.dart';

class MoodBloomApp extends ConsumerWidget {
  const MoodBloomApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // `currentThemeModeProvider` resolves the persisted
    // ThemeModePreference (system / light / dark / followDeviceTime)
    // into a concrete ThemeMode. Rebuilds whenever the user changes
    // the preference OR — for `followDeviceTime` — when the
    // 07:00 / 19:00 ticker inside the provider fires.
    final themeMode = ref.watch(currentThemeModeProvider);
    return MaterialApp.router(
      title: 'MoodBloom',
      // Hide the red "DEBUG" banner. Devs identify debug builds via
      // tooling (the Settings screen's "Crash now" button + the
      // dart.vm.product flag); the banner is just visual noise that
      // also appeared in screenshots and made the design feel
      // unfinished.
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      routerConfig: router,
      // The intervention banner host wraps every route so the Tier 1/2/3
      // banner can surface from any tab (Garden / History / Patterns /
      // Settings) once the [interventionControllerProvider] reaches
      // [InterventionPending]. The host is a transparent Stack — when
      // the controller is idle, the banner collapses to `SizedBox.shrink()`
      // and the routed `child` interacts normally.
      builder: (context, child) =>
          InterventionBannerHost(child: child ?? const SizedBox.shrink()),
    );
  }
}
