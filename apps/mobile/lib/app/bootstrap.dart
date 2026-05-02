import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/presentation/controllers/theme_mode_controller.dart';
import 'router.dart';
import 'theme.dart';

class MoodBloomApp extends ConsumerWidget {
  const MoodBloomApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    return MaterialApp.router(
      title: 'MoodBloom',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
