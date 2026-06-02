import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/intervention_dispatch.dart';
import '../widgets/dispatch_safe_defaults.dart';
import '../widgets/intervention_opt_out_button.dart';

/// Tier 3 surface - crisis resources, anchored on Hotline 1323.
///
/// Hard rules:
///   * Body is rendered verbatim from `dispatch.body` (already includes
///     "Hotline 1323" + the disclaimer footer). Falls back to the
///     [DispatchSafeDefaults.tier3] constant which is byte-for-byte
///     equal to `QuoteLibraryImpl.tier3Pool[0]` + footer.
///   * Hotline tile is the primary action; on Android/iOS it tries
///     `launchUrl('tel:1323')`. On Web (`kIsWeb`) it surfaces the
///     number in a dialog (browsers cannot dial telephones reliably).
///   * Three resource cards: a directory link, an "expect when you call"
///     expansion, and an "other resources" expansion with three child
///     hotlines.
///   * No close button at the top - leaving the screen requires either
///     opting out, tapping a resource, or back-gesture + confirmation.
///   * Back-gesture intercepted by [PopScope] with an "Are you sure?"
///     dialog whose only-pop button is the explicit "Close" choice.
class CrisisResourcesScreen extends ConsumerStatefulWidget {
  const CrisisResourcesScreen({this.dispatch, super.key});

  final InterventionDispatch? dispatch;

  @override
  ConsumerState<CrisisResourcesScreen> createState() =>
      _CrisisResourcesScreenState();
}

class _CrisisResourcesScreenState extends ConsumerState<CrisisResourcesScreen> {
  static const Logger _logger = Logger('intervention.crisis');

  String get _bodyText => widget.dispatch?.body ?? DispatchSafeDefaults.tier3;

  /// Launches a `tel:` URI on mobile; surfaces a dialog with the number
  /// on Web. Logs PII-free metadata (the number is not PII; the call
  /// itself is initiated by the OS, not by us).
  Future<void> _callNumber(String tel, {required String displayNumber}) async {
    if (kIsWeb) {
      await _showWebCallDialog(displayNumber);
      return;
    }
    final uri = Uri.parse('tel:$tel');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _logger.warn('launchUrl tel: failed', data: e.runtimeType.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Couldn't open the dialer. Please call $displayNumber.",
          ),
        ),
      );
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _logger.warn('launchUrl https failed', data: e.runtimeType.toString());
    }
  }

  Future<void> _showWebCallDialog(String displayNumber) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: const Text('Call this number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(displayNumber, style: theme.textTheme.displaySmall),
              const SizedBox(height: 12),
              const Text(
                'Free, 24 hours. Please dial from your phone.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text(
          'You can come back to this anytime. Hotline 1323 is always free, '
          '24 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mb = theme.extension<MbColors>();
    final textColor = mb?.text ?? theme.colorScheme.onSurface;
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmExit();
        if (shouldPop && context.mounted) context.pop();
      },
      child: Scaffold(
        // Tier 3 paints the errorContainer background for compassionate
        // prominence (existing behaviour preserved). Cap content width
        // on tablet/desktop so the prominent hotline tile and resource
        // stack stay legible on wide layouts.
        backgroundColor: theme.colorScheme.errorContainer,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      MbIconButton(
                        icon: const Icon(Icons.arrow_back),
                        semanticLabel: 'Close',
                        onPressed: () async {
                          final shouldPop = await _confirmExit();
                          if (shouldPop && context.mounted) context.pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We're here",
                    style: MbFonts.fraunces(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _bodyText,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _HotlineTile(
                    onTap: () => _callNumber('1323', displayNumber: '1323'),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.search),
                      title: const Text('Find a professional near you'),
                      subtitle: const Text(
                        'Department of Mental Health · dmh.go.th',
                      ),
                      onTap: () => _openLink('https://www.dmh.go.th'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ExpansionTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('What to expect when you call'),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: const [
                        Text(
                          "You'll hear a friendly hello. A trained listener will "
                          "ask how you're doing. You can share as much or as "
                          "little as feels right. There's no checklist, no "
                          "judgment.",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ExpansionTile(
                      leading: const Icon(Icons.list_alt),
                      title: const Text('Other resources'),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.phone),
                          title: const Text('Thai Suicide Helpline'),
                          subtitle: const Text('02-713-6793'),
                          onTap: () => _callNumber(
                            '0271336793',
                            displayNumber: '02-713-6793',
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.language),
                          title: const Text('iCare Foundation'),
                          subtitle: const Text('icarethailand.com'),
                          onTap: () =>
                              _openLink('https://icarethailand.com/th'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.local_hospital_outlined),
                          title: const Text('Emergency services'),
                          subtitle: const Text('1669'),
                          onTap: () =>
                              _callNumber('1669', displayNumber: '1669'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: InterventionOptOutButton(
                      label: "I'm okay for now",
                      onTapped: () {
                        if (context.mounted) context.pop();
                      },
                    ),
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

class _HotlineTile extends StatelessWidget {
  const _HotlineTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Call Hotline 1323, free, 24 hours, in Thai',
      child: Material(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.phone_in_talk,
                  size: 36,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Call Hotline 1323',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Free, 24 hours, in Thai.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
