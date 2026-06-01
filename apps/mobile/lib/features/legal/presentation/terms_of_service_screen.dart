import 'package:flutter/material.dart';

import 'legal_document_screen.dart';

/// Full MoodBloom terms of service, rendered in-app and linked from
/// Settings > About > Terms of service.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Terms of Service',
      effectiveDate: '1 June 2026',
      intro:
          'These terms govern your use of MoodBloom, a mood-tracking app built '
          'by KMUTT Group 2. By creating an account or using the app, you '
          'agree to these terms. Please read them together with our Privacy '
          'Policy.',
      sections: [
        LegalSection('1. Eligibility', [
          'You must be at least 13 years old to use MoodBloom. By using the '
              'app you confirm that you meet this requirement.',
        ]),
        LegalSection('2. Your account', [
          'You are responsible for keeping your account credentials and any '
              'device PIN secure, and for activity that occurs under your '
              'account. Tell us promptly if you believe your account has been '
              'compromised.',
        ]),
        LegalSection('3. Licence to use the app', [
          'We grant you a personal, non-exclusive, non-transferable, '
              'revocable licence to use MoodBloom for your own personal, '
              'non-commercial wellbeing journaling.',
        ]),
        LegalSection('4. Your content', [
          'You keep ownership of the moods, notes, and photos you create. You '
              'grant us only the limited permission needed to store, process, '
              'and display that content back to you so the app can function.',
          'You agree not to upload content that is unlawful or that infringes '
              'the rights of others.',
        ]),
        LegalSection('5. Acceptable use', [
          'You agree not to misuse the app: do not attempt to break its '
              'security, access other users\' data, disrupt the service, or '
              'use it to harm yourself or others.',
        ]),
        LegalSection('6. Not medical advice', [
          'MoodBloom is a self-reflection tool, not a medical device or a '
              'healthcare service. It cannot diagnose, treat, or prevent any '
              'condition, and its supportive prompts are not professional '
              'advice. Always seek the guidance of a qualified professional '
              'for medical or mental-health concerns. If you may be in danger, '
              'contact local emergency services or a crisis helpline '
              'immediately.',
        ]),
        LegalSection('7. Availability', [
          'MoodBloom is provided as a student project on an "as is" and "as '
              'available" basis. We may change, suspend, or discontinue '
              'features at any time, and we do not guarantee uninterrupted '
              'availability or that the app will be error-free.',
        ]),
        LegalSection('8. Limitation of liability', [
          'To the fullest extent permitted by law, MoodBloom and its team are '
              'not liable for any indirect, incidental, or consequential '
              'damages arising from your use of, or inability to use, the app. '
              'Nothing in these terms limits liability that cannot be limited '
              'under applicable law.',
        ]),
        LegalSection('9. Termination', [
          'You may stop using the app and delete your account at any time '
              'from Settings. We may suspend or end access if these terms are '
              'breached.',
        ]),
        LegalSection('10. Changes and governing law', [
          'We may update these terms; material changes will be reflected by '
              'the effective date above, and continued use means you accept '
              'the updated terms.',
          'These terms are governed by the laws of Thailand. Questions can be '
              'sent to the MoodBloom team at group2.moodbloom@kmutt.ac.th.',
        ]),
      ],
    );
  }
}
