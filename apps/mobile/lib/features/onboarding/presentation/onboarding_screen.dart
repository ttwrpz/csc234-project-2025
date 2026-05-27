import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/data/providers.dart';
import '../../notifications/data/datasources/fcm_datasource.dart'
    show FcmPermissionOutcome;
import '../../notifications/data/providers.dart'
    show fcmDatasourceProvider, notificationsPreferenceDatasourceProvider;
import 'widgets/onboarding_art.dart';

/// Five-slide onboarding deck for the v1.6 redesign.
///
/// Layout follows the prototype's `onboarding.jsx` `OnboardingScreen`:
/// fixed header (brand + slide counter), flex-grow centred body
/// (260×200 art slot, eyebrow, title, body), fixed footer (progress
/// dots, primary CTA, optional secondary text button).
///
/// Behaviour the screen preserves end-to-end:
///
///  * Carousel uses a `PageView` + dots-driven progress indicator.
///    Android system-back / browser-back / Esc walks the user
///    backwards through slides via [PopScope]; only slide 0 falls
///    through to the OS pop.
///  * Slide 3 ("Gentle nudges") calls
///    `FcmDatasource.requestPermission()` on its CTA — same code path
///    as the legacy `_NotificationsSlide`.
///  * Slide 4 ("Before you start") does **not** ack the bipolar /
///    medical disclaimer here. That ack lives behind the Patterns
///    gate (`insightsDisclaimerAcked` flag) so swiping through is
///    fine; "I understand" simply advances the deck.
///  * Final slide flips `onboarding_complete` in shared-prefs and
///    routes to `/sign-in` (when signed out) or `/home` (when a
///    session is already cached, e.g. cold-boot after a previous
///    install).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  bool _requestingPermission = false;

  /// Slides — kept top-level as a `const` list so each rebuild reuses
  /// the same instance. Strings are verbatim from the v1.6 prototype.
  static const List<_Slide> _slides = <_Slide>[
    _Slide(
      eyebrow: 'WELCOME',
      title: 'A quiet place\nfor your weather.',
      body:
          "MoodBloom is a garden you tend, one feeling at a time. We won't "
          'fix your mood. We\'ll hold space for it.',
      ctaLabel: 'Begin',
      secondaryLabel: 'Skip intro',
      art: OnboardingArtKind.welcome,
      kind: _SlideKind.intro,
    ),
    _Slide(
      eyebrow: 'LOG WHAT YOU FEEL',
      title: 'Six moods,\nyour intensity.',
      body:
          'Tap a mood, set how strongly you feel it (1 - 5), and add a note '
          'if you want. Logging takes seconds.',
      ctaLabel: 'Got it',
      secondaryLabel: 'Back',
      art: OnboardingArtKind.logMoods,
      kind: _SlideKind.intro,
    ),
    _Slide(
      eyebrow: 'WATCH YOUR GARDEN',
      title: 'Plants never wilt.\nOnly the weather changes.',
      body:
          'Each entry grows a plant. Five tiers - Flourishing to Storm Season '
          '- reflect the week without judging it.',
      ctaLabel: 'Tell me more',
      secondaryLabel: 'Back',
      art: OnboardingArtKind.gardenGrowth,
      kind: _SlideKind.intro,
    ),
    _Slide(
      eyebrow: 'GENTLE NUDGES',
      title: 'A soft reminder,\nonce a day.',
      body:
          'MoodBloom can send one gentle notification per day to invite a '
          "check-in. Around evening, your choice when. Change it anytime.",
      ctaLabel: 'Allow notifications',
      ctaIcon: Icons.notifications_outlined,
      secondaryLabel: 'Not now',
      art: OnboardingArtKind.notifications,
      kind: _SlideKind.notificationPermission,
    ),
    _Slide(
      eyebrow: 'BEFORE YOU START',
      title: 'Not a substitute\nfor care.',
      body:
          'MoodBloom is not a medical device. It cannot diagnose conditions '
          'like bipolar disorder, depression, or anxiety. Consult a qualified '
          'professional.',
      ctaLabel: 'I understand',
      ctaIcon: Icons.check,
      secondaryLabel: 'Read full disclaimer',
      art: OnboardingArtKind.disclaimer,
      kind: _SlideKind.disclaimer,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeAndRoute() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    // If a session is already cached (cold boot after a previous
    // install), bypass the auth screen and drop straight into Home.
    // Otherwise route to /sign-in — the router redirect would do this
    // for us, but explicitly going there keeps the intent visible.
    final signedIn = ref.read(currentUserStreamProvider).value != null;
    context.go(signedIn ? '/home' : '/sign-in');
  }

  void _next() {
    if (_index == _slides.length - 1) {
      // ignore: discarded_futures
      _completeAndRoute();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _back() {
    if (_index == 0) {
      // Slide 0 has no "Back" — pressing the secondary "Skip intro"
      // jumps to completion instead.
      // ignore: discarded_futures
      _completeAndRoute();
      return;
    }
    _controller.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _requestPermissionAndAdvance() async {
    if (_requestingPermission) return;
    setState(() => _requestingPermission = true);
    try {
      // Call the OS prompt directly. Routing through the higher-level
      // `NotificationsController.setEnabled` would short-circuit here
      // because no user is signed in yet — see the original
      // `_NotificationsSlide` for the full rationale.
      final outcome = await ref.read(fcmDatasourceProvider).requestPermission();
      final granted = outcome == FcmPermissionOutcome.granted;
      final preference = ref.read(notificationsPreferenceDatasourceProvider);
      await preference?.setCheerUpEnabled(granted);
    } finally {
      if (mounted) setState(() => _requestingPermission = false);
    }
    if (!mounted) return;
    _next();
  }

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final isFirst = _index == 0;

    return PopScope(
      canPop: isFirst,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _back();
      },
      child: Scaffold(
        backgroundColor: mb.bg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final formFactor = w >= MbBreakpoints.desktop
                  ? _FormFactor.desktop
                  : (w >= MbBreakpoints.phone
                        ? _FormFactor.tablet
                        : _FormFactor.phone);
              final maxWidth = switch (formFactor) {
                _FormFactor.phone => 480.0,
                _FormFactor.tablet => 720.0,
                _FormFactor.desktop => 960.0,
              };
              final padX = formFactor == _FormFactor.phone ? 20.0 : 28.0;
              const padY = 28.0;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: padX,
                      vertical: padY,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(currentIndex: _index, total: _slides.length),
                        Expanded(
                          child: PageView.builder(
                            controller: _controller,
                            itemCount: _slides.length,
                            onPageChanged: (i) => setState(() => _index = i),
                            itemBuilder: (context, i) => _SlideBody(
                              slide: _slides[i],
                              factor: formFactor,
                            ),
                          ),
                        ),
                        _Footer(
                          slide: _slides[_index],
                          currentIndex: _index,
                          total: _slides.length,
                          requestingPermission: _requestingPermission,
                          onPrimary: () {
                            final slide = _slides[_index];
                            if (slide.kind ==
                                _SlideKind.notificationPermission) {
                              // ignore: discarded_futures
                              _requestPermissionAndAdvance();
                            } else {
                              _next();
                            }
                          },
                          onSecondary: () {
                            final slide = _slides[_index];
                            if (_index == 0) {
                              // "Skip intro" — jump straight to completion.
                              // ignore: discarded_futures
                              _completeAndRoute();
                            } else if (slide.kind ==
                                    _SlideKind.notificationPermission ||
                                slide.kind == _SlideKind.disclaimer) {
                              // "Not now" / "Read full disclaimer" both just
                              // advance the deck — the full disclaimer is
                              // surfaced again at the Patterns ack gate.
                              _next();
                            } else {
                              _back();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _FormFactor { phone, tablet, desktop }

/// Behavioural kind of a slide. Drives which CTA path runs when the
/// primary button is tapped — the visual layout is the same for all
/// slides, so this enum is invisible to the renderer.
enum _SlideKind { intro, notificationPermission, disclaimer }

@immutable
class _Slide {
  const _Slide({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.secondaryLabel,
    required this.art,
    required this.kind,
    this.ctaIcon,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String ctaLabel;
  final String secondaryLabel;
  final OnboardingArtKind art;
  final _SlideKind kind;
  final IconData? ctaIcon;
}

// ---------------------------------------------------------------------------
// Header — brand bloom + wordmark on the left, slide counter on the right
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.currentIndex, required this.total});

  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          // 28×28 gradient tile + wordmark. Matches the side-nav brand
          // row at a smaller scale.
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [MoodBloomColors.seed, MoodBloomColors.seedDark],
              ),
            ),
            child: const Center(
              child: MbBrandSvg(size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'MoodBloom',
            style: MbFonts.fraunces(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: mb.text,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          Text(
            '${currentIndex + 1} / $total',
            style: MbFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: mb.textDim,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide body — art, eyebrow, title, body
// ---------------------------------------------------------------------------

class _SlideBody extends StatelessWidget {
  const _SlideBody({required this.slide, required this.factor});

  final _Slide slide;
  final _FormFactor factor;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    // Per the prototype: non-disclaimer slides use a larger headline
    // (28/32/36 across phone/tablet/desktop). The disclaimer slide's
    // title is intentionally smaller (26/28/30) so the longer
    // "Not a substitute for care." sentence stays balanced.
    final isDisclaimer = slide.kind == _SlideKind.disclaimer;
    final titleSize = isDisclaimer
        ? switch (factor) {
            _FormFactor.phone => 26.0,
            _FormFactor.tablet => 28.0,
            _FormFactor.desktop => 30.0,
          }
        : switch (factor) {
            _FormFactor.phone => 28.0,
            _FormFactor.tablet => 32.0,
            _FormFactor.desktop => 36.0,
          };

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          OnboardingArt(kind: slide.art),
          const SizedBox(height: 22),
          Text(
            slide.eyebrow,
            style: MbFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: mb.textDim,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: MbFonts.fraunces(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              color: mb.text,
              height: 1.15,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              slide.body,
              textAlign: TextAlign.center,
              style: MbFonts.nunito(
                fontSize: 14,
                height: 1.55,
                color: mb.textDim,
              ),
            ),
          ),
          if (slide.kind == _SlideKind.notificationPermission) ...<Widget>[
            const SizedBox(height: 18),
            const _DefaultTimeChip(),
          ],
        ],
      ),
    );
  }
}

/// Soft-green pill showing the default reminder time. Rendered on the
/// notification-permission slide only, between the body copy and the
/// footer. Matches the prototype's `<div>Default time · 9:30 PM</div>`
/// chip - the actual scheduling lives in Settings; this is purely an
/// informational hint that the reminder defaults to evening.
class _DefaultTimeChip extends StatelessWidget {
  const _DefaultTimeChip();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? MoodBloomColors.seed.withValues(alpha: 0.18)
        : MoodBloomColors.softGreen;
    final fg = isDark ? const Color(0xFFCDE8DA) : MoodBloomColors.seedDark;
    return Semantics(
      label: 'Default reminder time, 9:30 PM',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.schedule, size: 14, color: fg),
            const SizedBox(width: 8),
            Text(
              'Default time · 9:30 PM',
              style: MbFonts.nunito(
                fontSize: 12,
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

// ---------------------------------------------------------------------------
// Footer — progress dots, primary CTA, optional secondary text button
// ---------------------------------------------------------------------------

class _Footer extends StatelessWidget {
  const _Footer({
    required this.slide,
    required this.currentIndex,
    required this.total,
    required this.requestingPermission,
    required this.onPrimary,
    required this.onSecondary,
  });

  final _Slide slide;
  final int currentIndex;
  final int total;
  final bool requestingPermission;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final isPermission = slide.kind == _SlideKind.notificationPermission;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ProgressDots(currentIndex: currentIndex, total: total),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: MbPrimaryButton(
            label: isPermission && requestingPermission
                ? 'Requesting…'
                : slide.ctaLabel,
            onPressed: isPermission && requestingPermission ? null : onPrimary,
            leading: slide.ctaIcon == null
                ? null
                : Icon(slide.ctaIcon, size: 18, color: Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        // Reserve a fixed 22 dp slot for the secondary text button so
        // the primary CTA never shifts up/down between slides.
        SizedBox(
          height: 22,
          child: TextButton(
            onPressed: onSecondary,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              slide.secondaryLabel,
              style: MbFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: mb.textDim,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.currentIndex, required this.total});

  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: i == currentIndex ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == currentIndex ? MoodBloomColors.seed : mb.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}
