import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// One heading + its paragraphs within a legal document.
class LegalSection {
  const LegalSection(this.heading, this.paragraphs);

  final String heading;
  final List<String> paragraphs;
}

/// Reusable read-only renderer for a long-form legal document (privacy
/// policy, terms of service). Renders a titled, scrollable column of
/// headed sections with an "Effective" date line. Pure presentation - the
/// document content is supplied by the caller so the same chrome serves
/// every legal surface.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.effectiveDate,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String effectiveDate;
  final String intro;
  final List<LegalSection> sections;

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
          title,
          style: MbFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: mb.text,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            MoodBloomSpacing.pagePadding,
            8,
            MoodBloomSpacing.pagePadding,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Effective $effectiveDate',
                style: MbFonts.nunito(fontSize: 12, color: mb.textDim),
              ),
              const SizedBox(height: 12),
              Text(
                intro,
                style: MbFonts.nunito(
                  fontSize: 14,
                  height: 1.6,
                  color: mb.text,
                ),
              ),
              const SizedBox(height: 8),
              for (final section in sections) ...[
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
        ),
      ),
    );
  }
}
