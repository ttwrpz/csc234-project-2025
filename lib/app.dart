import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'config/constants.dart';
import 'models/mood_entry.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/entry_detail/entry_detail_screen.dart';

class MoodBloomApp extends StatelessWidget {
  const MoodBloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AppStartup(),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        );
      case AppRoutes.auth:
        return MaterialPageRoute(
          builder: (_) => const AuthScreen(),
        );
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
      case AppRoutes.entryDetail:
        final entry = settings.arguments as MoodEntry;
        return MaterialPageRoute(
          builder: (_) => EntryDetailScreen(entry: entry),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const AuthScreen(),
        );
    }
  }
}

class _AppStartup extends StatefulWidget {
  const _AppStartup();

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigate();
    });
  }

  Future<void> _navigate() async {
    final settings = context.read<SettingsProvider>();

    // Wait for settings to load
    if (!settings.isLoaded) {
      await settings.loadSettings();
    }

    if (!mounted) return;

    // Check onboarding
    if (!settings.onboardingSeen) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      return;
    }

    // Check auth state
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('\u{1F33B}', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
