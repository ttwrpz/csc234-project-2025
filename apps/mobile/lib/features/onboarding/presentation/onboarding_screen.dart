import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets/onboarding_slide.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = <_SlideData>[
    _SlideData(
      icon: Icons.local_florist_outlined,
      title: 'Welcome to MoodBloom',
      body:
          "A quiet space to notice how you're feeling. "
          'No streaks, no pressure — just a record.',
    ),
    _SlideData(
      icon: Icons.edit_note_outlined,
      title: 'Log a mood in 30 seconds',
      body:
          'Pick a feeling, slide an intensity from 1 to 5, '
          'and add a note if it helps.',
    ),
    _SlideData(
      icon: Icons.history_toggle_off_outlined,
      title: 'Your history is yours',
      body:
          "Today's entries are editable. Past days stay as they were "
          '— a record, not a redo.',
    ),
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    context.go('/home');
  }

  void _next() {
    if (_index == _slides.length - 1) {
      _complete();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (!isLast)
            TextButton(onPressed: _complete, child: const Text('Skip')),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final s = _slides[i];
                return OnboardingSlide(
                  icon: s.icon,
                  title: s.title,
                  body: s.body,
                );
              },
            ),
          ),
          _Dots(count: _slides.length, activeIndex: _index),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                child: Text(isLast ? 'Get started' : 'Next'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.activeIndex});
  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 24 : 8,
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
