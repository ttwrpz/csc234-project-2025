import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../disclaimer/presentation/widgets/disclaimer_panel.dart';
import '../../notifications/data/datasources/fcm_datasource.dart'
    show FcmPermissionOutcome;
import '../../notifications/data/providers.dart'
    show fcmDatasourceProvider, notificationsPreferenceDatasourceProvider;
import 'widgets/onboarding_slide.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  /// Phone/tablet/desktop breakpoints — mirrored from
  /// `_AppShell._tabletMin / _desktopMin` in `app/router.dart` so the
  /// responsive behaviour is consistent app-wide.
  static const double _tabletMin = 600;
  static const double _desktopMin = 900;

  /// Onboarding deck — 5 slides across BOTH Web and Android. The
  /// notification-permission slide ships on every platform now: Android
  /// 13+ also requires a runtime POST_NOTIFICATIONS prompt, which
  /// `FirebaseMessaging.requestPermission()` triggers from
  /// `FcmDatasource` — same code path as Web's browser permission
  /// prompt. Removing the platform fork keeps the carousel consistent
  /// and avoids a "permission asked in Settings later" surprise.
  ///
  /// The 3 art-driven slides keep their original copy; the disclaimer
  /// slide (S5 feature 7.4 — pulled forward) sits before the "Watch
  /// patterns emerge" + "Get started" CTA so that remains the user's
  /// last touch.
  late final List<_SlideKind> _slideKinds = const <_SlideKind>[
    _SlideKind.gardenScene,
    _SlideKind.logEntry,
    _SlideKind.notifications,
    _SlideKind.disclaimer,
    _SlideKind.patterns,
  ];

  /// Per-slide art, memoised in a RepaintBoundary so the heavy
  /// CustomPaint isn't replayed on every parent rebuild (e.g. window
  /// resize on web flipping the layout enum). The surrounding slide
  /// shell is composed every build to honour the active layout.
  late final List<Widget> _slideArts = _slideKinds
      .map<Widget>(
        (kind) => RepaintBoundary(child: _buildArt(kind)),
      )
      .toList(growable: false);

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    context.go('/home');
  }

  void _next() {
    if (_index == _slideKinds.length - 1) {
      _complete();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  void _back() {
    if (_index == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final isLast = _index == _slideKinds.length - 1;
    final isFirst = _index == 0;

    // PopScope intercepts Android system back / browser back / desktop
    // Esc so the user navigates between slides instead of exiting the
    // carousel. On the first slide, fall through (`canPop: true`) so
    // the OS handles the gesture normally — that's the user's only way
    // to leave onboarding from slide 0 without completing it.
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
              final layout = w >= _desktopMin
                  ? OnboardingLayout.desktop
                  : (w >= _tabletMin
                        ? OnboardingLayout.tablet
                        : OnboardingLayout.phone);
              final shellMaxWidth = switch (layout) {
                OnboardingLayout.desktop => 960.0,
                OnboardingLayout.tablet => 720.0,
                OnboardingLayout.phone => 480.0,
              };
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: shellMaxWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: layout == OnboardingLayout.phone ? 20 : 28,
                      vertical: 28,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView(
                            controller: _controller,
                            onPageChanged: (i) => setState(() => _index = i),
                            children: [
                              for (var i = 0; i < _slideKinds.length; i += 1)
                                _buildSlide(
                                  _slideKinds[i],
                                  _slideArts[i],
                                  layout,
                                ),
                            ],
                          ),
                        ),
                        _Dots(count: _slideKinds.length, activeIndex: _index),
                        const SizedBox(height: 20),
                        // Slide 0 shows only the centred Next button —
                        // no empty Back slot to make the row feel
                        // lopsided. Slide 1+ shows Back + Next.
                        if (isFirst)
                          MbPrimaryButton(
                            key: const ValueKey('cta-next'),
                            label: 'Next',
                            onPressed: _next,
                          )
                        else
                          Row(
                            children: [
                              MbGhostButton(
                                label: 'Back',
                                onPressed: _back,
                                fullWidth: false,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: MbPrimaryButton(
                                  key: ValueKey(
                                    isLast ? 'cta-done' : 'cta-next',
                                  ),
                                  label: isLast ? 'Get started' : 'Next',
                                  onPressed: _next,
                                  leading: isLast
                                      ? const Icon(
                                          Icons.arrow_forward,
                                          size: 18,
                                        )
                                      : null,
                                ),
                              ),
                            ],
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

  /// Builds the slide widget for the given kind under the chosen
  /// responsive layout. The 3 art-driven slides use `OnboardingSlide`,
  /// which handles the phone/tablet/desktop variants internally. The
  /// disclaimer + notifications slides stay vertically stacked
  /// (centered) since their content is denser and benefits from a
  /// single reading column.
  Widget _buildSlide(_SlideKind kind, Widget art, OnboardingLayout layout) {
    switch (kind) {
      case _SlideKind.gardenScene:
        return OnboardingSlide(
          art: art,
          layout: layout,
          title: 'Meet your garden',
          body:
              'Your feelings become a living scene. Nothing to fix — just to '
              'notice.',
        );
      case _SlideKind.logEntry:
        return OnboardingSlide(
          art: art,
          layout: layout,
          title: 'Log how you feel',
          body:
              'Pick a mood, slide the intensity, and write as much or as '
              'little as you want.',
        );
      case _SlideKind.patterns:
        return OnboardingSlide(
          art: art,
          layout: layout,
          title: 'Watch patterns emerge',
          body:
              'Over time, gentle insights appear. Your history is safe, '
              'private, and yours.',
        );
      case _SlideKind.disclaimer:
        return _DisclaimerSlide(art: art, layout: layout);
      case _SlideKind.notifications:
        return _NotificationsSlide(art: art, layout: layout);
    }
  }

  /// Builds the inline brand art for a slide. The art widget is wrapped
  /// in a `RepaintBoundary` higher up (`_slideArts`) so its size
  /// container stays small and stable across layout variants.
  Widget _buildArt(_SlideKind kind) {
    // The art container is large enough to read comfortably on phone
    // and to fill the tablet/desktop column without scaling up. The
    // inner painter scales its own 200×160 viewBox to fill.
    if (kind == _SlideKind.disclaimer) {
      return SizedBox(
        width: 260,
        height: 200,
        child: CustomPaint(painter: _DisclaimerArtPainter()),
      );
    }
    if (kind == _SlideKind.notifications) {
      return SizedBox(
        width: 260,
        height: 200,
        child: CustomPaint(painter: _NotificationsArtPainter()),
      );
    }
    return SizedBox(
      width: 260,
      height: 200,
      child: CustomPaint(painter: _OnboardingArtPainter(kind)),
    );
  }
}

/// Carousel slide kinds. Names match the painter cases for the
/// art-driven slides; `disclaimer` and `notifications` have no painter
/// case (they render their own widgets). `notifications` ships on every
/// platform — Android 13+ also needs the runtime POST_NOTIFICATIONS
/// prompt, which `FirebaseMessaging.requestPermission()` triggers
/// transparently via `FcmDatasource`.
enum _SlideKind { gardenScene, logEntry, patterns, disclaimer, notifications }

/// Custom slide for the bipolar / medical disclaimer (S5 feature 7.4 —
/// pulled forward). Mirrors `OnboardingSlide`'s typography (Fraunces 26
/// title + Nunito 13 dim caption) so the carousel feels consistent;
/// swaps the inline brand art for a [DisclaimerPanel].
///
/// The slide does NOT call `disclaimerRepository.ack()` automatically.
/// The ack-tracking flag (`users/{uid}.insightsDisclaimerAcked`) flips
/// only when the user taps "I understand" in the (S5) Insights ack
/// dialog. Swiping past this slide is fine — onboarding completion is
/// a separate concern.
class _DisclaimerSlide extends StatelessWidget {
  const _DisclaimerSlide({required this.art, required this.layout});

  final Widget art;
  final OnboardingLayout layout;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final isPhone = layout == OnboardingLayout.phone;
    final title = Text(
      'A note about MoodBloom',
      style: MbFonts.fraunces(
        fontSize: isPhone
            ? 26
            : (layout == OnboardingLayout.desktop ? 30 : 28),
        fontWeight: FontWeight.w600,
        color: mb.text,
      ),
      textAlign: isPhone ? TextAlign.center : TextAlign.start,
    );
    const body = DisclaimerPanel();

    return Semantics(
      label: 'A note about MoodBloom',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: switch (layout) {
          OnboardingLayout.phone => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              art,
              const SizedBox(height: 24),
              title,
              const SizedBox(height: 14),
              body,
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
                  children: [title, const SizedBox(height: 14), body],
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
                  children: [title, const SizedBox(height: 14), body],
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}

/// Cross-platform onboarding slide that explains why MoodBloom needs
/// notification permission and offers an inline "Allow notifications"
/// button. The button calls
/// `notificationsControllerProvider.setEnabled(true)`, which in turn
/// triggers `FcmDatasource.requestPermission()` — that's the only path
/// that opens the browser permission prompt on Web AND the Android
/// 13+ POST_NOTIFICATIONS runtime prompt. Skipping is fine; the
/// cheer-up reminders Settings tile is still discoverable later.
class _NotificationsSlide extends ConsumerStatefulWidget {
  const _NotificationsSlide({required this.art, required this.layout});

  final Widget art;
  final OnboardingLayout layout;

  @override
  ConsumerState<_NotificationsSlide> createState() =>
      _NotificationsSlideState();
}

class _NotificationsSlideState extends ConsumerState<_NotificationsSlide> {
  bool _requesting = false;
  bool _granted = false;
  bool _denied = false;
  String? _failureMessage;

  /// `true` when the OS reports the permission as already granted on
  /// entry — we skip the prompt entirely and show a confirmation row
  /// instead. Mirrors the iOS/Android settings-detect that the user
  /// asked for: the slide should know if it was already approved
  /// before showing the Allow button.
  bool _alreadyGranted = false;

  @override
  void initState() {
    super.initState();
    // Read existing permission status WITHOUT prompting. If the OS
    // (Android 13+ notification permission, web Notification API,
    // iOS UNAuthorization) already reports granted/denied, surface
    // that state instead of asking again.
    WidgetsBinding.instance.addPostFrameCallback((_) => _detectExisting());
  }

  Future<void> _detectExisting() async {
    final outcome = await ref
        .read(fcmDatasourceProvider)
        .currentPermission();
    if (!mounted) return;
    // v1.6 fix — only treat `granted` as a definitive initial state.
    // On Android 13+ `getNotificationSettings()` reports `denied` for
    // the not-yet-asked-too case, and on iOS the same happens after a
    // first denial. Auto-setting `_denied = true` here would hide the
    // "Allow notifications" button and strand the user with no way to
    // trigger the OS prompt. Leave `_denied = false` until the user
    // actually taps the button and the request comes back denied —
    // that path is where the prompt gets a real shot.
    if (outcome == FcmPermissionOutcome.granted) {
      setState(() {
        _granted = true;
        _alreadyGranted = true;
      });
    }
  }

  Future<void> _request() async {
    setState(() {
      _requesting = true;
      _failureMessage = null;
    });

    // v1.6 fix — call the OS permission request DIRECTLY instead of
    // routing through `NotificationsController.setEnabled`. Onboarding
    // runs BEFORE sign-in (the auth gate redirect only kicks in after
    // `onboarding_complete` is flipped), so during this slide the
    // signed-in user is null. `setEnabled` short-circuits with no uid
    // and writes the local preference WITHOUT firing
    // `FcmDatasource.requestPermission()` — which is the only call
    // that actually triggers the OS dialog on web / Android 13+ / iOS.
    // Going direct guarantees the prompt fires on every platform.
    //
    // Token registration is intentionally deferred to post-sign-in:
    // the local cheer-up flag we set here gets reconciled with
    // Firestore by `NotificationsController._attachRemoteStream` once
    // the user signs in, and the first toggle tap in Settings
    // performs the `upsertToken` (which re-uses the already-granted
    // OS permission — no second prompt).
    final stopwatch = Stopwatch()..start();
    final outcome = await ref.read(fcmDatasourceProvider).requestPermission();
    stopwatch.stop();
    if (!mounted) return;

    final granted = outcome == FcmPermissionOutcome.granted;
    final preference = ref.read(notificationsPreferenceDatasourceProvider);
    await preference?.setCheerUpEnabled(granted);
    if (!mounted) return;

    // Heuristic: a sub-250ms "grant" means the OS returned the
    // already-granted state without re-prompting. Surface that with a
    // different message so the user understands no dialog was shown.
    final fastGrant =
        granted && stopwatch.elapsed < const Duration(milliseconds: 250);
    setState(() {
      _requesting = false;
      _granted = granted;
      _denied = !granted;
      _alreadyGranted = fastGrant;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    final layout = widget.layout;
    final isPhone = layout == OnboardingLayout.phone;
    final crossAxis = isPhone
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final textAlign = isPhone ? TextAlign.center : TextAlign.start;

    final title = Text(
      'Stay connected',
      textAlign: textAlign,
      style: MbFonts.fraunces(
        fontSize: isPhone
            ? 26
            : (layout == OnboardingLayout.desktop ? 30 : 28),
        fontWeight: FontWeight.w600,
        color: mb.text,
      ),
    );
    final String bodyCopy;
    if (_granted && _alreadyGranted) {
      bodyCopy =
          "You've already allowed notifications for MoodBloom — nothing "
          'else to do here. You can revoke this in your device or '
          'browser settings any time.';
    } else if (_granted) {
      bodyCopy = "Thanks — we'll only nudge if your week looks heavy.";
    } else if (_denied) {
      bodyCopy =
          'Looks like the request was declined. Tap below to try again, '
          "or open your device's notification settings to allow MoodBloom "
          'manually.';
    } else {
      bodyCopy =
          'MoodBloom needs notification permission so cheer-up reminders '
          "can find you when it's a heavy week. Your device will ask you "
          'to allow this. You can turn it off later in Settings.';
    }
    final body = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Text(
        bodyCopy,
        textAlign: textAlign,
        style: MbFonts.nunito(
          fontSize: 15,
          height: 1.55,
          color: mb.textDim,
        ),
      ),
    );

    // v1.6 — single button surface that stays visible until permission
    // is actually granted. On the very first tap we get the OS dialog;
    // on subsequent denied taps the OS may suppress the prompt (Android
    // 13+ stops asking after two declines) — that's fine, the user can
    // still see the button and follow the body copy's "open device
    // settings" hint to fix it manually. The button only disappears
    // once `_granted == true`, replaced by a confirmation row.
    final Widget actionRow;
    if (_granted) {
      actionRow = Row(
        mainAxisAlignment: isPhone
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            _alreadyGranted ? 'Already allowed' : 'Permission granted',
            style: MbFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      );
    } else {
      // Label leans on "Try again" after a first denial to signal the
      // retry-affordance; the underlying onPressed is identical.
      final label = _requesting
          ? 'Requesting…'
          : (_denied ? 'Try again' : 'Allow notifications');
      actionRow = Align(
        alignment: isPhone ? Alignment.center : Alignment.centerLeft,
        child: MbPrimaryButton(
          label: label,
          onPressed: _requesting ? null : _request,
          fullWidth: false,
        ),
      );
    }

    final copyColumn = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: crossAxis,
      children: [
        title,
        const SizedBox(height: 10),
        body,
        const SizedBox(height: 18),
        actionRow,
        if (_failureMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            _failureMessage!,
            textAlign: textAlign,
            style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
          ),
        ],
      ],
    );

    return Semantics(
      label: 'Stay connected — notification permission request',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: switch (layout) {
          OnboardingLayout.phone => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [widget.art, const SizedBox(height: 24), copyColumn],
          ),
          OnboardingLayout.tablet => Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 6, child: Center(child: widget.art)),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: copyColumn),
            ],
          ),
          OnboardingLayout.desktop => Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Center(child: widget.art)),
              const SizedBox(width: 32),
              Expanded(child: copyColumn),
            ],
          ),
        },
      ),
    );
  }
}

/// Inline brand art for the "Stay connected" notifications slide.
/// v1.6 redesign — replaces the prior bell-and-leaf composition with a
/// friendly **envelope-and-heart card** scene: a soft envelope sits
/// centre, a small white card with a coral heart peeks out from
/// inside, two amber sparkles drift above, and a gentle "delivery"
/// wave line passes beneath. Reads as "we'll reach you with care"
/// rather than the alarm-clock semantics of a bell. Keeps the
/// 200×160 viewBox + sky-gradient backdrop conventions of the other
/// onboarding painters.
class _NotificationsArtPainter extends CustomPainter {
  static const _skyTop = Color(0xFFFFE4D1);
  static const _skyBot = Color(0xFFE8F3ED);
  static const _amber = Color(0xFFE8A23B);
  static const _coral = Color(0xFFE77A8C);
  static const _primary = Color(0xFF2E7D5B);
  static const _paper = Color(0xFFFFFFFF);
  static const _shadow = Color(0xFFE8D9C5);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 160);

    // Backdrop — sky gradient with rounded corners.
    final bgRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 200, 160),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      bgRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skyTop, _skyBot],
        ).createShader(const Rect.fromLTWH(0, 0, 200, 160)),
    );

    // Sparkles — small amber 4-pointed marks scattered above the
    // envelope, hinting at a fresh delivery.
    _drawSparkle(canvas, const Offset(38, 38), 5);
    _drawSparkle(canvas, const Offset(168, 46), 4);
    _drawSparkle(canvas, const Offset(160, 102), 3);

    // Envelope drop-shadow (offset 4 dp down + right).
    final envShadow = RRect.fromRectAndRadius(
      const Rect.fromLTWH(48, 78, 110, 64),
      const Radius.circular(8),
    );
    canvas.drawRRect(envShadow, Paint()..color = _shadow);

    // Envelope body.
    final envRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(44, 74, 110, 64),
      const Radius.circular(8),
    );
    canvas.drawRRect(envRect, Paint()..color = _paper);
    canvas.drawRRect(
      envRect,
      Paint()
        ..color = _shadow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Card emerging from the envelope. Sits behind the front flap
    // (drawn next) so the top edge is hidden — looks like a real
    // letter being pulled out.
    canvas.save();
    canvas.translate(99, 60);
    canvas.rotate(-0.06);
    final card = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-32, 0, 64, 56),
      const Radius.circular(6),
    );
    canvas.drawRRect(card, Paint()..color = _paper);
    canvas.drawRRect(
      card,
      Paint()
        ..color = _shadow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Heart in the centre of the card — the warm payload.
    final heart = Path()
      ..moveTo(0, 18)
      ..cubicTo(-12, 6, -22, 18, -16, 28)
      ..cubicTo(-10, 36, -4, 38, 0, 44)
      ..cubicTo(4, 38, 10, 36, 16, 28)
      ..cubicTo(22, 18, 12, 6, 0, 18)
      ..close();
    canvas.drawPath(heart, Paint()..color = _coral);
    canvas.restore();

    // Envelope front flap — a V drawn over the bottom edge of the
    // card so the card peeks above and the flap below covers the
    // lower half. Pure stroke, not filled, so the card shows through.
    final flap = Path()
      ..moveTo(44, 80)
      ..lineTo(99, 115)
      ..lineTo(154, 80);
    canvas.drawPath(
      flap,
      Paint()
        ..color = _shadow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Soft "delivery" wave underneath the envelope — two short curves
    // in primary green at 40 % alpha, suggesting gentle outreach.
    final wave = Paint()
      ..color = _primary.withAlpha(0x66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final wavePath = Path()
      ..moveTo(60, 150)
      ..cubicTo(80, 144, 120, 156, 140, 150);
    canvas.drawPath(wavePath, wave);

    canvas.restore();
  }

  /// Small 4-pointed sparkle — two thin crossed ovals scaled by [r].
  /// Used as an ambient decoration above the envelope.
  void _drawSparkle(Canvas canvas, Offset center, double r) {
    final paint = Paint()..color = _amber.withAlpha(0xCC);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 2, height: r / 1.6),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r / 1.6, height: r * 2),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NotificationsArtPainter oldDelegate) => false;
}

/// Inline brand art for the "A note about MoodBloom" disclaimer slide.
/// v1.6 redesign — replaces the heart-and-medical-cross composition
/// (which felt closer to "clinical care" than the slide's actual
/// "this is a friendly note, not a medical device" intent) with an
/// **open notebook page** featuring three placeholder text lines, a
/// small `i` info-mark in primary green, a coral bookmark ribbon
/// hanging from the top, a leaf accent floating beside the page, and
/// an amber pencil resting along the bottom. Reads as "have a quick
/// read" instead of "see a doctor". Keeps the 200×160 viewBox + sky-
/// gradient backdrop conventions of the other onboarding painters.
class _DisclaimerArtPainter extends CustomPainter {
  static const _skyTop = Color(0xFFE8F3ED);
  static const _skyBot = Color(0xFFFFE4D1);
  static const _primary = Color(0xFF2E7D5B);
  static const _coral = Color(0xFFE77A8C);
  static const _amber = Color(0xFFE8A23B);
  static const _paper = Color(0xFFFAF7EE);
  static const _shadow = Color(0xFFE8D9C5);
  static const _line = Color(0xFFD6DDE4);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 160);

    // Backdrop — reverse mint→peach gradient differentiates this
    // slide from the garden-scene slide's peach→mint.
    final bgRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 200, 160),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      bgRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skyTop, _skyBot],
        ).createShader(const Rect.fromLTWH(0, 0, 200, 160)),
    );

    // Notebook back shadow (offset 4 dp down + right).
    final backRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(40, 36, 120, 92),
      const Radius.circular(6),
    );
    canvas.drawRRect(backRect, Paint()..color = _shadow);

    // Notebook page (front).
    final pageRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(36, 32, 120, 92),
      const Radius.circular(6),
    );
    canvas.drawRRect(pageRect, Paint()..color = _paper);
    canvas.drawRRect(
      pageRect,
      Paint()
        ..color = _shadow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Spine guide — vertical coral hair-line down the left margin,
    // mimicking a notebook's binding indicator.
    canvas.drawLine(
      const Offset(48, 38),
      const Offset(48, 118),
      Paint()
        ..color = _coral.withAlpha(0x99)
        ..strokeWidth = 1.5,
    );

    // Three placeholder text lines on the page.
    final lineFill = Paint()..color = _line;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(58, 50, 78, 5),
        const Radius.circular(2.5),
      ),
      lineFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(58, 62, 86, 5),
        const Radius.circular(2.5),
      ),
      lineFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(58, 74, 56, 5),
        const Radius.circular(2.5),
      ),
      lineFill,
    );

    // Info-mark — small "i in a circle" glyph in primary green,
    // anchored to the lower-left of the page so it reads as a
    // gentle "heads up" rather than a clinical icon.
    const markCenter = Offset(72, 102);
    canvas.drawCircle(
      markCenter,
      9,
      Paint()..color = _primary.withAlpha(0x33),
    );
    canvas.drawCircle(
      markCenter,
      9,
      Paint()
        ..color = _primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    // Dot of the "i".
    canvas.drawCircle(
      const Offset(72, 98),
      1.4,
      Paint()..color = _primary,
    );
    // Stem of the "i".
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(71, 101, 2, 6),
        const Radius.circular(1),
      ),
      Paint()..color = _primary,
    );

    // Bookmark ribbon hanging from the top edge of the page — coral
    // pennant with a forked tail.
    final ribbon = Path()
      ..moveTo(136, 32)
      ..lineTo(136, 58)
      ..lineTo(142, 53)
      ..lineTo(148, 58)
      ..lineTo(148, 32)
      ..close();
    canvas.drawPath(ribbon, Paint()..color = _coral);

    // Leaf accent next to the page — keeps the garden vocabulary
    // present so the disclaimer slide doesn't read as a hospital
    // form.
    canvas.save();
    canvas.translate(162, 78);
    canvas.rotate(0.42);
    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(14, -10, 24, 0)
      ..quadraticBezierTo(14, 10, 0, 0)
      ..close();
    canvas.drawPath(leaf, Paint()..color = _primary);
    // Leaf vein.
    canvas.drawLine(
      const Offset(0, 0),
      const Offset(22, 0),
      Paint()
        ..color = _paper.withAlpha(0x99)
        ..strokeWidth = 0.8,
    );
    canvas.restore();

    // Pencil resting along the bottom edge of the notebook — amber
    // shaft, paper-shadow tip, with a small graphite dot.
    canvas.save();
    canvas.translate(44, 132);
    canvas.rotate(-0.05);
    final shaft = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 76, 6),
      const Radius.circular(2),
    );
    canvas.drawRRect(shaft, Paint()..color = _amber);
    // Eraser cap (coral) at the left end.
    final eraser = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-6, 0, 8, 6),
      const Radius.circular(2),
    );
    canvas.drawRRect(eraser, Paint()..color = _coral);
    // Pencil tip cone on the right.
    final tip = Path()
      ..moveTo(76, 0)
      ..lineTo(86, 3)
      ..lineTo(76, 6)
      ..close();
    canvas.drawPath(tip, Paint()..color = _shadow);
    // Graphite dot at the very tip.
    canvas.drawCircle(
      const Offset(85, 3),
      1.1,
      Paint()..color = const Color(0xFF2A2A2A),
    );
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DisclaimerArtPainter oldDelegate) => false;
}

/// Page-indicator dots. Active is `colorScheme.primary` (the brand
/// green); inactive is `onSurface.withAlpha(0x40)` so it adapts to
/// both `mb.bg` light AND dark backgrounds. The previous 12 % black
/// fill (`Colors.black.withAlpha(0x1F)`) was invisible on the dark
/// navy surface — now the inactive dots stay readable in both modes.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.activeIndex});
  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactive = theme.colorScheme.onSurface.withAlpha(0x40);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: active ? 22 : 6,
          decoration: BoxDecoration(
            color: active ? theme.colorScheme.primary : inactive,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

/// Inline brand art for the three art-driven onboarding slides.
/// Transcribed from the React prototype's SVGs (`screens.jsx` lines
/// 1–93). The viewBox is 200×160 so we paint into a 260×200 canvas and
/// scale uniformly. The `disclaimer` slide has no painter case — it
/// composes a `DisclaimerPanel` instead.
class _OnboardingArtPainter extends CustomPainter {
  _OnboardingArtPainter(this.kind);

  final _SlideKind kind;

  // Palette mirrors `data.jsx` PALETTE constants used in the prototype.
  static const _skyTop = Color(0xFFFFE4D1);
  static const _skyBot = Color(0xFFE8F3ED);
  static const _ground = Color(0xFF8FBFA3);
  static const _stem = Color(0xFF4C8B6A);
  static const _amber = Color(0xFFE8A23B);
  static const _coral = Color(0xFFE77A8C);
  static const _yellow = Color(0xFFF6C45A);
  static const _peach = Color(0xFFF6A86B);
  static const _primary = Color(0xFF2E7D5B);
  static const _line = Color(0xFFD6DDE4);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 160);

    switch (kind) {
      case _SlideKind.gardenScene:
        _paintGarden(canvas);
      case _SlideKind.logEntry:
        _paintLogEntry(canvas);
      case _SlideKind.patterns:
        _paintPatterns(canvas);
      case _SlideKind.disclaimer:
      case _SlideKind.notifications:
        // No painter — these slides render their own content and
        // never instantiate this painter. The cases are here so the
        // exhaustive switch passes the analyser.
        break;
    }
    canvas.restore();
  }

  void _paintGarden(Canvas canvas) {
    // Backdrop with rounded corners + sky gradient.
    final bgRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 200, 160),
      const Radius.circular(18),
    );
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_skyTop, _skyBot],
      ).createShader(const Rect.fromLTWH(0, 0, 200, 160));
    canvas.drawRRect(bgRect, bgPaint);

    // Sun.
    canvas.drawCircle(
      const Offset(160, 36),
      18,
      Paint()..color = _yellow.withAlpha(0xCC), // 0.8 opacity
    );

    // Ground (filled curve from x=0 to x=200).
    final ground = Path()
      ..moveTo(0, 130)
      ..cubicTo(60, 110, 140, 140, 200, 120)
      ..lineTo(200, 160)
      ..lineTo(0, 160)
      ..close();
    canvas.drawPath(ground, Paint()..color = _ground);

    // Coral flower (50, 120).
    final stemPaint = Paint()
      ..color = _stem
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(50, 120), const Offset(50, 150), stemPaint);
    canvas.drawCircle(const Offset(50, 120), 10, Paint()..color = _coral);
    canvas.drawCircle(const Offset(50, 120), 4, Paint()..color = _yellow);

    // Yellow sunflower (110, 110).
    canvas.drawLine(const Offset(110, 110), const Offset(110, 150), stemPaint);
    canvas.drawCircle(const Offset(110, 110), 12, Paint()..color = _yellow);
    canvas.drawCircle(const Offset(110, 110), 5, Paint()..color = _amber);

    // Peach bud (150, 125).
    canvas.drawLine(const Offset(150, 125), const Offset(150, 150), stemPaint);
    canvas.drawCircle(const Offset(150, 125), 8, Paint()..color = _peach);
  }

  void _paintLogEntry(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 200, 160),
        const Radius.circular(18),
      ),
      Paint()..color = _skyBot,
    );

    // Top "mood" card (white).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 30, 160, 40),
        const Radius.circular(12),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(const Offset(40, 50), 10, Paint()..color = _yellow);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(58, 44, 80, 6),
        const Radius.circular(3),
      ),
      Paint()..color = _line,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(58, 54, 50, 6),
        const Radius.circular(3),
      ),
      Paint()..color = _line,
    );

    // Slider track + filled portion + knob.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 84, 160, 8),
        const Radius.circular(4),
      ),
      Paint()..color = _line,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 84, 110, 8),
        const Radius.circular(4),
      ),
      Paint()..color = _primary,
    );
    canvas.drawCircle(const Offset(130, 88), 9, Paint()..color = Colors.white);
    canvas.drawCircle(
      const Offset(130, 88),
      9,
      Paint()
        ..color = _primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Note card.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 108, 160, 34),
        const Radius.circular(10),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 118, 100, 5),
        const Radius.circular(2.5),
      ),
      Paint()..color = _line,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 128, 60, 5),
        const Radius.circular(2.5),
      ),
      Paint()..color = _line,
    );
  }

  void _paintPatterns(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 200, 160),
        const Radius.circular(18),
      ),
      Paint()..color = _skyTop,
    );

    // Trend polyline.
    final points = const <Offset>[
      Offset(20, 110),
      Offset(50, 80),
      Offset(75, 95),
      Offset(105, 55),
      Offset(135, 70),
      Offset(170, 40),
    ];
    final linePaint = Paint()
      ..color = _primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);
    final dotPaint = Paint()..color = _primary;
    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
    }

    // Pill summary.
    final pill = Paint()..color = Colors.white.withAlpha(0xCC);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 125, 160, 20),
        const Radius.circular(8),
      ),
      pill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 132, 80, 6),
        const Radius.circular(3),
      ),
      Paint()..color = _primary,
    );
  }

  @override
  bool shouldRepaint(covariant _OnboardingArtPainter oldDelegate) =>
      oldDelegate.kind != kind;
}
