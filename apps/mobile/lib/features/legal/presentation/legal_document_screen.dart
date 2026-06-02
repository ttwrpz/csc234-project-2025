import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// One heading + its paragraphs within a legal document.
class LegalSection {
  const LegalSection(this.heading, this.paragraphs);

  final String heading;
  final List<String> paragraphs;
}

/// Data for a complete long-form legal document (privacy policy, terms of
/// service). Content only, so the same source renders both as a full route
/// screen and as a modal overlay.
class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.effectiveDate,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String effectiveDate;
  final String intro;
  final List<LegalSection> sections;
}

/// Full-screen route renderer, linked from Settings > About. The overlay
/// variant for the sign-in / sign-up screens is [showLegalDocument].
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Scaffold(
      backgroundColor: mb.bg,
      appBar: AppBar(
        backgroundColor: mb.bg,
        foregroundColor: mb.text,
        elevation: 0,
        title: Text(
          document.title,
          style: MbFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: mb.text,
          ),
        ),
      ),
      body: SafeArea(top: false, child: LegalDocumentView(document: document)),
    );
  }
}

/// Scaffold-less scrollable body: effective date, intro, then headed
/// sections. Shared by [LegalDocumentScreen] and the modal shell.
class LegalDocumentView extends StatelessWidget {
  const LegalDocumentView({super.key, required this.document, this.padding});

  final LegalDocument document;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return SingleChildScrollView(
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            MoodBloomSpacing.pagePadding,
            8,
            MoodBloomSpacing.pagePadding,
            32,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Effective ${document.effectiveDate}',
            style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
          ),
          const SizedBox(height: 12),
          Text(
            document.intro,
            style: MbFonts.nunito(fontSize: 14, height: 1.6, color: mb.text),
          ),
          const SizedBox(height: 8),
          for (final section in document.sections) ...[
            const SizedBox(height: 20),
            Text(
              section.heading,
              style: MbFonts.fraunces(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: mb.text,
              ),
            ),
            const SizedBox(height: 8),
            for (final paragraph in section.paragraphs) ...[
              Text(
                paragraph,
                style: MbFonts.nunito(
                  fontSize: 14,
                  height: 1.6,
                  color: mb.text,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

/// Presents [document] as an overlay: a centred dialog on wide
/// (tablet/desktop) viewports, a near-full-height bottom sheet on phones.
/// Router-independent on purpose - the sign-in / sign-up screens are
/// unauthenticated, where pushing the `/legal/*` route can be intercepted
/// by the auth redirect, so an overlay is the reliable surface there.
Future<void> showLegalDocument(BuildContext context, LegalDocument document) {
  final size = MediaQuery.of(context).size;
  final mb = Theme.of(context).extension<MbColors>()!;
  const wideBreakpoint = 600.0;

  if (size.width >= wideBreakpoint) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: mb.bg,
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoodBloomSpacing.radiusCardLg),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 640,
            maxHeight: size.height * 0.85,
          ),
          child: _LegalModalShell(document: document),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: mb.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(MoodBloomSpacing.radiusCardLg),
      ),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.92,
      child: _LegalModalShell(document: document, showHandle: true),
    ),
  );
}

/// Shared chrome for the overlay: optional drag handle, a title + close
/// header, then the scrollable [LegalDocumentView].
class _LegalModalShell extends StatelessWidget {
  const _LegalModalShell({required this.document, this.showHandle = false});

  final LegalDocument document;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final mb = Theme.of(context).extension<MbColors>()!;
    return Column(
      children: [
        if (showHandle) ...[
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: mb.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MoodBloomSpacing.pagePadding,
            8,
            8,
            4,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  document.title,
                  style: MbFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: mb.text,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                color: mb.textDim,
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: mb.line),
        Expanded(child: LegalDocumentView(document: document)),
      ],
    );
  }
}
