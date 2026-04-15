import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/garden_provider.dart';
import '../../providers/settings_provider.dart';
import '../../config/theme.dart';
import '../../utils/date_helpers.dart';
import '../../utils/responsive.dart';
import '../../widgets/streak_badge.dart';
import '../../models/mood_type.dart';
import 'garden_view.dart';
import '../log_mood/log_mood_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      context.read<MoodProvider>().loadEntries(auth.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final useRail = Responsive.isWide(context);

    final pages = [
      const _GardenTab(),
      const LogMoodScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    final content = IndexedStack(index: _currentIndex, children: pages);

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 16),
                child: Text('\u{1F33B}', style: TextStyle(fontSize: 28)),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.local_florist_outlined),
                  selectedIcon: Icon(Icons.local_florist),
                  label: Text('Garden'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.add_circle_outline),
                  selectedIcon: Icon(Icons.add_circle),
                  label: Text('Log Mood'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: Text('History'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: content),
          ],
        ),
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton(
                onPressed: () => setState(() => _currentIndex = 1),
                child: const Icon(Icons.add),
              )
            : null,
      );
    }

    return Scaffold(
      body: content,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_florist_outlined),
            activeIcon: Icon(Icons.local_florist),
            label: 'Garden',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Log Mood',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => setState(() => _currentIndex = 1),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _GardenTab extends StatelessWidget {
  const _GardenTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final moodProvider = context.watch<MoodProvider>();
    final gardenProvider = context.watch<GardenProvider>();
    final settings = context.watch<SettingsProvider>();

    final displayName =
        auth.user?.displayName ?? auth.userProfile?.displayName ?? 'there';
    final greeting = DateHelpers.getGreeting();

    // Update garden whenever entries change
    gardenProvider.setAnimationSpeed(settings.animationSpeed);
    gardenProvider.updateGarden(moodProvider.last30DaysEntries);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final gardenHeight = screenWidth >= 600 ? 450.0 : 340.0;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          if (auth.user != null) {
            await moodProvider.refreshEntries(auth.user!.uid);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  const SizedBox(height: 8),
                  Text(
                    '$greeting, $displayName!',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateHelpers.formatShort(DateTime.now()),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Streak
                  StreakBadge(streak: moodProvider.streakCount),
                  const SizedBox(height: 16),

                  // Garden
                  Container(
                    height: gardenHeight,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: moodProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : gardenProvider.elements.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '\u{1F331}',
                                  style: TextStyle(fontSize: 48),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Your garden is empty',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Log your first mood to start growing!',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          )
                        : const GardenView(),
                  ),
                  const SizedBox(height: 20),

                  // Weekly Summary
                  Text(
                    'This Week',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  _WeeklySummary(entries: moodProvider.thisWeekEntries),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeeklySummary extends StatelessWidget {
  final List<dynamic> entries;

  const _WeeklySummary({required this.entries});

  @override
  Widget build(BuildContext context) {
    final weekDays = DateHelpers.getWeekDays();
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final dayEntries = entries
              .where((e) => DateHelpers.isSameDay(e.createdAt, weekDays[i]))
              .toList();
          final hasMood = dayEntries.isNotEmpty;
          final isToday = DateHelpers.isSameDay(weekDays[i], DateTime.now());
          final mood = hasMood
              ? MoodType.fromString(dayEntries.first.mood)
              : null;

          return Column(
            children: [
              Text(
                dayLabels[i],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: isToday ? FontWeight.bold : null,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: hasMood
                      ? (mood?.color ?? AppColors.primary).withValues(
                          alpha: 0.2,
                        )
                      : isToday
                      ? AppColors.divider
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Center(
                  child: hasMood
                      ? Text(
                          mood?.emoji ?? '\u{2022}',
                          style: const TextStyle(fontSize: 16),
                        )
                      : null,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
